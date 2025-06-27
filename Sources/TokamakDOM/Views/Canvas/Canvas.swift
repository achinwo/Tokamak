// Copyright 2020-2021 Tokamak contributors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
//  Created by Carson Katri on 9/17/21.
//

import Foundation
import JavaScriptKit
@_spi(TokamakCore) import TokamakCore
import TokamakStaticHTML

extension Canvas: DOMPrimitive {
  public var renderedBody: AnyView {
    AnyView(_Canvas(parent: self))
  }
}

extension Canvas: @MainActor SpacerContainer {
  public var hasSpacer: Bool { true }
  public var axis: SpacerContainerAxis { .vertical }
  public var fillCrossAxis: Bool { true }
}

private let devicePixelRatio = JSObject.global.devicePixelRatio.number ?? 1

struct _Canvas<Symbols: View>: View {
  let parent: Canvas<Symbols>

  @StateObject
  private var coordinator = Coordinator()

  @Environment(\.inAnimatingTimelineView)
  private var inAnimatingTimelineView

  @Environment(\.isAnimatingTimelineViewPaused)
  private var isAnimatingTimelineViewPaused

  final class Coordinator: ObservableObject {
    @Published
    var canvas: JSObject?

    var currentDrawLoop: JSValue?

    /// A cache of resolved symbols by their tag.
    /// This allows symbols to be used in an animated canvas.
    var symbolCache: [AnyHashable: JSObject] = [:]
  }

  func cacheSymbol(id: AnyHashable, _ img: JSObject) {
    coordinator.symbolCache[id] = img
  }

  func cachedSymbol(id: AnyHashable) -> JSObject? {
    coordinator.symbolCache[id]
  }

  var body: some View {
    GeometryReader { proxy in
      HTML(
        "canvas",
        [
          "style": "width: 100%; height: 100%;"
        ]
      )
      ._domRef($coordinator.canvas)
      .onAppear { draw(in: proxy.size) }
      ._onUpdate {
        // Cancel the previous animation loop.
        if let currentDrawLoop = coordinator.currentDrawLoop {
          _ = JSObject.global.cancelAnimationFrame!(currentDrawLoop)
        }
        draw(in: proxy.size)
      }
    }
  }

  private func draw(in size: CGSize) {
    guard let canvas = coordinator.canvas,
      let canvasContext = canvas.getContext!("2d").object
    else { return }
    // Setup the canvas size
    canvas.width = .number(Double(size.width * CGFloat(devicePixelRatio)))
    canvas.height = .number(Double(size.height * CGFloat(devicePixelRatio)))
    // Restore the initial state.
    _ = canvasContext.restore!()
    // Clear the canvas.
    _ = canvasContext.clearRect!(0, 0, canvas.width, canvas.height)
    // Save the cleared state for the next redraw to restore.
    _ = canvasContext.save!()
    // Scale for retina displays
    _ = canvasContext.scale!(devicePixelRatio, devicePixelRatio)
    // Create a fresh context.
    var graphicsContext = parent._makeContext(
      onOperation: { storage, operation in
        handleOperation(storage, operation, in: canvasContext)
      },
      imageResolver: resolveImage,
      textResolver: resolveText(in: canvasContext),
      symbolResolver: resolveSymbol
    )
    // Render into the context.
    parent.renderer(&graphicsContext, size)
    if inAnimatingTimelineView && !isAnimatingTimelineViewPaused {
      coordinator.currentDrawLoop = JSObject.global.requestAnimationFrame!(
        JSOneshotClosure { _ in
          draw(in: size)
          return .undefined
        })
    }
  }

  private func handleOperation(
    _ storage: GraphicsContext._Storage,
    _ operation: GraphicsContext._Storage._Operation,
    in canvasContext: JSObject
  ) {
    canvasContext.globalCompositeOperation = .string(storage.blendMode.cssValue)
    switch operation {
    case .clip(let path, _, _):
      clip(to: path, in: canvasContext)
    case .beginClipLayer:
      _ = canvasContext.save!()
    case .endClipLayer:
      _ = canvasContext.restore!()
      _ = canvasContext.clip!()
    case .addFilter(let filter, _):
      applyFilter(filter, to: canvasContext)
    case .beginLayer:
      _ = canvasContext.save!()
    case .endLayer:
      _ = canvasContext.restore!()
    case .fill(let path, let shading, let fillStyle):
      fillPath(path, with: shading, style: fillStyle, in: canvasContext)
    case .stroke(let path, let shading, let strokeStyle):
      strokePath(path, with: shading, style: strokeStyle, in: canvasContext)
    case .drawImage(let image, let positioning, let style):
      drawImage(image, at: positioning, with: style, in: canvasContext)
    case .drawText(let text, let positioning):
      drawText(text, at: positioning, in: canvasContext)
    case .drawSymbol(let symbol, let positioning):
      drawSymbol(symbol, at: positioning, in: canvasContext)
    }
  }

  private func applyFilter(_ filter: GraphicsContext.Filter, to canvasContext: JSObject) {
    let previousFilter =
      canvasContext.filter
        .string == "none" ? "" : (canvasContext.filter.string ?? "")
    switch filter._storage {
    case .projectionTransform(let matrix):
      _ = canvasContext.transform!(
        Double(matrix.m11), Double(matrix.m12),
        Double(matrix.m21), Double(matrix.m22),
        Double(matrix.m31), Double(matrix.m32)
      )
    case .shadow(let color, let radius, let x, let y, _, _):
      canvasContext
        .shadowColor = .string(
          _ColorProxy(color ?? Color(.sRGBLinear, white: 0, opacity: 0.33)).resolve(
            in: parent._environment
          )
          .cssValue
        )
      canvasContext.shadowBlur = .number(Double(radius))
      canvasContext.shadowOffsetX = .number(Double(x))
      canvasContext.shadowOffsetY = .number(Double(y))
    case .colorMultiply:
      break
    case .colorMatrix:
      break
    case .hueRotation(let angle):
      canvasContext.filter = .string("\(previousFilter) hue-rotate(\(angle.radians)rad)")
    case .saturation(let amount):
      canvasContext.filter = .string("\(previousFilter) saturate(\(amount * 100)%)")
    case .brightness(let amount):
      canvasContext.filter = .string("\(previousFilter) brightness(\(amount * 100)%)")
    case .contrast(let amount):
      canvasContext.filter = .string("\(previousFilter) contrast(\(amount * 100)%)")
    case .colorInvert(let amount):
      canvasContext.filter = .string("\(previousFilter) invert(\(amount * 100)%)")
    case .grayscale(let amount):
      canvasContext.filter = .string("\(previousFilter) grayscale(\(amount * 100)%)")
    case .luminanceToAlpha:
      break
    case .blur(let radius, _):
      canvasContext.filter = .string("\(previousFilter) blur(\(radius)px)")
    case .alphaThreshold:
      break
    }
  }
}

extension GraphicsContext.Shading {
  func cssValue(
    in environment: EnvironmentValues,
    with canvas: JSObject,
    bounds: CGRect
  ) -> JSValue {
    if case .resolved(let resolved) = _resolve(in: environment)._storage {
      return resolved.cssValue(in: environment, with: canvas, bounds: bounds)
    }
    return .string("none")
  }
}

extension GraphicsContext._ResolvedShading {
  func cssValue(
    in environment: EnvironmentValues,
    with canvas: JSObject,
    bounds: CGRect
  ) -> JSValue {
    switch self {
    case .levels(let palette):
      guard let primary = palette.first else { break }
      return primary.cssValue(in: environment, with: canvas, bounds: bounds)
    case .style(let style):
      return style.cssValue(in: environment, with: canvas, bounds: bounds)
    case .gradient(let gradient, let geometry, _):
      let gradientBounds = CGRect(origin: .zero, size: .init(width: 1, height: 1))
      switch geometry {
      case .axial(let startPoint, let endPoint):
        return _ResolvedStyle.gradient(
          gradient,
          style: .linear(
            startPoint: .init(x: startPoint.x, y: startPoint.y),
            endPoint: .init(x: endPoint.x, y: endPoint.y)
          )
        ).cssValue(in: environment, with: canvas, bounds: gradientBounds)
      case .conic(let center, let angle):
        return _ResolvedStyle.gradient(
          gradient,
          style: .angular(
            center: .init(x: center.x, y: center.y),
            startAngle: .degrees(0),
            endAngle: angle
          )
        ).cssValue(in: environment, with: canvas, bounds: gradientBounds)
      case .radial(let center, let startRadius, let endRadius):
        return _ResolvedStyle.gradient(
          gradient,
          style: .radial(
            center: .init(x: center.x, y: center.y),
            startRadius: startRadius,
            endRadius: endRadius
          )
        ).cssValue(in: environment, with: canvas, bounds: gradientBounds)
      }
    case .tiledImage:
      break
    }
    return .string("none")
  }
}

extension _ResolvedStyle {
  func cssValue(
    in environment: EnvironmentValues,
    opacity: Float = 1,
    with canvas: JSObject,
    bounds: CGRect
  ) -> JSValue {
    switch self {
    case .color(let color):
      return .string(color.opacity(color.opacity * Double(opacity)).cssValue)
    case .foregroundMaterial:
      break
    case .array(let palette):
      guard let primary = palette.first else { break }
      return primary.cssValue(in: environment, opacity: opacity, with: canvas, bounds: bounds)
    case .opacity(let opacity, let style):
      return style.cssValue(in: environment, opacity: opacity, with: canvas, bounds: bounds)
    case .gradient(let gradient, let style):
      let canvasGradient: JSObject
      switch style {
      case .linear(let startPoint, let endPoint):
        canvasGradient = canvas.createLinearGradient!(
          Double(bounds.origin.x + startPoint.x * bounds.width),
          Double(bounds.origin.y + startPoint.y * bounds.height),
          Double(bounds.origin.x + endPoint.x * bounds.width),
          Double(bounds.origin.y + endPoint.y * bounds.height)
        ).object!
      case .radial(let center, let startRadius, let endRadius):
        canvasGradient = canvas.createRadialGradient!(
          Double(bounds.origin.x + center.x * bounds.width),
          Double(bounds.origin.y + center.y * bounds.height),
          Double(startRadius),
          Double(bounds.origin.x + center.x * bounds.width),
          Double(bounds.origin.y + center.y * bounds.height),
          Double(endRadius)
        ).object!
      case .elliptical(let center, let startRadiusFraction, let endRadiusFraction):
        canvasGradient = canvas.createRadialGradient!(
          Double(bounds.origin.x + center.x * bounds.width),
          Double(bounds.origin.y + center.y * bounds.height),
          Double(startRadiusFraction * bounds.width),
          Double(bounds.origin.x + center.x * bounds.width),
          Double(bounds.origin.y + center.y * bounds.height),
          Double(endRadiusFraction * bounds.width)
        ).object!
      case .angular(let center, _, let endAngle):
        canvasGradient = canvas.createConicGradient!(
          Double(endAngle.radians),
          Double(bounds.origin.x + center.x * bounds.width),
          Double(bounds.origin.y + center.y * bounds.height)
        ).object!
      }
      for stop in gradient.stops {
        _ = canvasGradient.addColorStop!(
          Double(stop.location),
          _ColorProxy(stop.color).resolve(in: environment).cssValue
        )
      }
      return .object(canvasGradient)
    }
    return .string("")
  }
}

extension AnyColorBox.ResolvedValue {
  func opacity(_ opacity: Double) -> Self {
    .init(
      red: red,
      green: green,
      blue: blue,
      opacity: opacity,
      space: space
    )
  }
}

extension GraphicsContext.BlendMode {
  var cssValue: String {
    switch self {
    case .normal: return "normal"
    case .multiply: return "multiply"
    case .screen: return "screen"
    case .overlay: return "overlay"
    case .darken: return "darken"
    case .lighten: return "lighten"
    case .colorDodge: return "color-dodge"
    case .colorBurn: return "color-burn"
    case .softLight: return "soft-light"
    case .hardLight: return "hard-light"
    case .difference: return "difference"
    case .exclusion: return "exclusion"
    case .hue: return "hue"
    case .saturation: return "saturation"
    case .color: return "color"
    case .luminosity: return "luminosity"
    case .clear: return "clear"
    case .copy: return "copy"
    case .sourceIn: return "source-in"
    case .sourceOut: return "source-out"
    case .sourceAtop: return "source-atop"
    case .destinationOver: return "destination-over"
    case .destinationIn: return "destination-in"
    case .destinationOut: return "destination-out"
    case .destinationAtop: return "destination-atop"
    case .xor: return "xor"
    case .plusDarker: return "darken"
    case .plusLighter: return "lighten"
    }
  }
}
