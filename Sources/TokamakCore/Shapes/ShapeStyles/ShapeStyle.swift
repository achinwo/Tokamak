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
//  Created by Carson Katri on 7/6/21.
//

import Foundation

@MainActor
public protocol ShapeStyle {
  func _apply(to shape: inout _ShapeStyle_Shape)
  static func _apply(to type: inout _ShapeStyle_ShapeType)
}

public struct AnyShapeStyle: ShapeStyle {
  let styles:
    (
      primary: ShapeStyle,
      secondary: ShapeStyle,
      tertiary: ShapeStyle,
      quaternary: ShapeStyle
    )
  var stylesArray: [ShapeStyle] {
    [styles.primary, styles.secondary, styles.tertiary, styles.quaternary]
  }

  let environment: EnvironmentValues

  public func _apply(to shape: inout _ShapeStyle_Shape) {
    shape.environment = environment
    let results = stylesArray.map { style -> _ShapeStyle_Shape.Result in
      var copy = shape
      style._apply(to: &copy)
      return copy.result
    }
    shape
      .result =
      .resolved(.array(results.compactMap { $0.resolvedStyle(on: shape, in: environment) }))

    switch shape.operation {
    case .prepare(let text, let level):
      var modifiers = text.modifiers
      if let color = shape.result.resolvedStyle(on: shape, in: environment)?.color(at: level) {
        modifiers.insert(.color(color), at: 0)
      }
      shape.result = .prepared(Text(storage: text.storage, modifiers: modifiers))
    case .resolveStyle(let levels):
      if case .resolved(let resolved) = shape.result {
        if case .array(let children) = resolved,
          children.count >= levels.upperBound
        {
          shape.result = .resolved(.array(.init(children[levels])))
        }
      } else if let resolved = shape.result.resolvedStyle(on: shape, in: environment) {
        shape.result = .resolved(resolved)
      }
    default:
      // TODO: Handle other operations.
      break
    }
  }

  public static func _apply(to type: inout _ShapeStyle_ShapeType) {}
}

@MainActor
public struct _ShapeStyle_Shape {
  public let operation: Operation
  public var result: Result
  public var environment: EnvironmentValues
  public var bounds: CGRect?
  public var role: ShapeRole
  public var inRecursiveStyle: Bool

  public init(
    for operation: Operation,
    in environment: EnvironmentValues,
    role: ShapeRole
  ) {
    self.operation = operation
    result = .none
    self.environment = environment
    bounds = nil
    self.role = role
    inRecursiveStyle = false
  }

  public enum Operation {
    case prepare(Text, level: Int)
    case resolveStyle(levels: Range<Int>)
    case fallbackColor(level: Int)
    case multiLevel
    case copyForeground
    case primaryStyle
    case modifyBackground
  }

  @MainActor
  public enum Result {
    case prepared(Text)
    case resolved(_ResolvedStyle)
    case style(AnyShapeStyle)
    case color(Color)
    case bool(Bool)
    case none

    public func resolvedStyle(
      on shape: _ShapeStyle_Shape,
      in environment: EnvironmentValues
    ) -> _ResolvedStyle? {
      switch self {
      case .resolved(let resolved): return resolved
      case .style(let anyStyle):
        var copy = shape
        anyStyle._apply(to: &copy)
        return copy.result.resolvedStyle(on: shape, in: environment)
      case .color(let color):
        return .color(color.provider.resolve(in: environment))
      default:
        return nil
      }
    }
  }
}

public struct _ShapeStyle_ShapeType {}

@MainActor
public indirect enum _ResolvedStyle {
  case color(AnyColorBox.ResolvedValue)
  //  case paint(AnyResolvedPaint) // I think is used for Image as a ShapeStyle (SwiftUI.ImagePaint).
  case foregroundMaterial(AnyColorBox.ResolvedValue, _MaterialStyle)
  //  case backgroundMaterial(AnyColorBox.ResolvedValue)
  case array([_ResolvedStyle])
  case opacity(Float, _ResolvedStyle)
  //  case multicolor(ResolvedMulticolorStyle)
  case gradient(Gradient, style: _GradientStyle)

  public func color(at level: Int) -> Color? {
    switch self {
    case .color(let resolved):
      return Color(_ConcreteColorBox(resolved))
    case .foregroundMaterial(let resolved, _):
      return Color(_ConcreteColorBox(resolved))
    case .array(let children):
      return children[level].color(at: level)
    case .opacity(let opacity, let resolved):
      guard let color = resolved.color(at: level) else { return nil }
      return color.opacity(Double(opacity))
    case .gradient(let gradient, _):
      return gradient.stops.first?.color
    }
  }
}
