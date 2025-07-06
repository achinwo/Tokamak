// Copyright 2020 Tokamak contributors
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
//  Created by Carson Katri on 7/11/21.
//

import Foundation

public class _AnimationBoxBase: Equatable, @unchecked Sendable {

  init() {}

  public struct _Resolved {
    public var duration: Double {
      switch style {
      case .timingCurve(_, _, _, _, let duration):
        return duration
      case .solver(let solver):
        return solver.restingPoint(precision: 0.01)
      }
    }

    public var delay: Double
    public var speed: Double
    public var repeatStyle: _RepeatStyle
    public var style: _Style

    public init(
      delay: Double,
      speed: Double = 1,
      repeatStyle: _RepeatStyle = .fixed(1, autoreverses: true),
      style: _Style
    ) {
      self.delay = delay
      self.speed = speed
      self.repeatStyle = repeatStyle
      self.style = style
    }

    public enum _Style: Equatable, Sendable {
      case timingCurve(Double, Double, Double, Double, duration: Double)
      case solver(_AnimationSolver)

      public static func == (lhs: Self, rhs: Self) -> Bool {
        switch lhs {
        case .timingCurve(let lhs0, let lhs1, let lhs2, let lhs3, let lhsDuration):
          if case .timingCurve(let rhs0, let rhs1, let rhs2, let rhs3, let rhsDuration) = rhs {
            return lhs0 == rhs0
              && lhs1 == rhs1
              && lhs2 == rhs2
              && lhs3 == rhs3
              && lhsDuration == rhsDuration
          }
        case .solver(let lhsSolver):
          if case .solver(let rhsSolver) = rhs {
            return type(of: lhsSolver) == type(of: rhsSolver)
          }
        }
        return false
      }
    }

    public enum _RepeatStyle: Equatable {
      case fixed(Int, autoreverses: Bool)
      case forever(autoreverses: Bool)

      public var autoreverses: Bool {
        switch self {
        case .fixed(_, let autoreverses),
          .forever(let autoreverses):
          return autoreverses
        }
      }
    }
  }

  func resolve() -> _Resolved {
    fatalError("implement \(#function) in subclass")
  }

  func equals(_ other: _AnimationBoxBase) -> Bool {
    fatalError("implement \(#function) in subclass")
  }

  public static func == (lhs: _AnimationBoxBase, rhs: _AnimationBoxBase) -> Bool {
    lhs.equals(rhs)
  }
}

final class StyleAnimationBox: _AnimationBoxBase, @unchecked Sendable {
  let style: _Resolved._Style

  init(style: _Resolved._Style) {
    self.style = style
  }

  override func resolve() -> _AnimationBoxBase._Resolved {
    .init(delay: 0, speed: 1, repeatStyle: .fixed(1, autoreverses: true), style: style)
  }

  override func equals(_ other: _AnimationBoxBase) -> Bool {
    guard let other = other as? StyleAnimationBox else { return false }
    return style == other.style
  }
}

final class DelayedAnimationBox: _AnimationBoxBase, @unchecked Sendable {
  let delay: Double
  let parent: _AnimationBoxBase

  init(delay: Double, parent: _AnimationBoxBase) {
    self.delay = delay
    self.parent = parent
  }

  override func resolve() -> _AnimationBoxBase._Resolved {
    var resolved = parent.resolve()
    resolved.delay = delay
    return resolved
  }

  override func equals(_ other: _AnimationBoxBase) -> Bool {
    guard let other = other as? DelayedAnimationBox else { return false }
    return delay == other.delay && parent.equals(other.parent)
  }
}

final class RetimedAnimationBox: _AnimationBoxBase, @unchecked Sendable {
  let speed: Double
  let parent: _AnimationBoxBase

  init(speed: Double, parent: _AnimationBoxBase) {
    self.speed = speed
    self.parent = parent
  }

  override func resolve() -> _AnimationBoxBase._Resolved {
    var resolved = parent.resolve()
    resolved.speed = speed
    return resolved
  }

  override func equals(_ other: _AnimationBoxBase) -> Bool {
    guard let other = other as? RetimedAnimationBox else { return false }
    return speed == other.speed && parent.equals(other.parent)
  }
}

final class RepeatedAnimationBox: _AnimationBoxBase, @unchecked Sendable {
  let style: _AnimationBoxBase._Resolved._RepeatStyle
  let parent: _AnimationBoxBase

  init(style: _AnimationBoxBase._Resolved._RepeatStyle, parent: _AnimationBoxBase) {
    self.style = style
    self.parent = parent
  }

  override func resolve() -> _AnimationBoxBase._Resolved {
    var resolved = parent.resolve()
    resolved.repeatStyle = style
    return resolved
  }

  override func equals(_ other: _AnimationBoxBase) -> Bool {
    guard let other = other as? RepeatedAnimationBox else { return false }
    return style == other.style && parent.equals(other.parent)
  }
}
