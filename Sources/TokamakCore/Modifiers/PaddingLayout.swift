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

import Foundation

public struct _PaddingLayout: ViewModifier {
  public var edges: Edge.Set
  public var insets: EdgeInsets?

  public init(edges: Edge.Set = .all, insets: EdgeInsets?) {
    self.edges = edges
    self.insets = insets
  }

  public func body(content: Content) -> some View {
    content
  }
}

extension _PaddingLayout: @MainActor Animatable {
  public typealias AnimatableData = EmptyAnimatableData
}

extension View {
  public func padding(_ insets: EdgeInsets) -> ModifiedContent<Self, _PaddingLayout> {
    modifier(_PaddingLayout(insets: insets))
  }

  public func padding(
    _ edges: Edge.Set = .all,
    _ length: CGFloat? = nil
  ) -> ModifiedContent<Self, _PaddingLayout> {
    let insets = length.map { EdgeInsets(_all: $0) }
    return modifier(_PaddingLayout(edges: edges, insets: insets))
  }

  public func padding(_ length: CGFloat) -> ModifiedContent<Self, _PaddingLayout> {
    padding(.all, length)
  }
}

extension ModifiedContent where Modifier == _PaddingLayout, Content: View {

  @MainActor
  public func padding(_ length: CGFloat) -> ModifiedContent<Content, _PaddingLayout> {
    var layout = modifier
    layout.insets?.top += length
    layout.insets?.leading += length
    layout.insets?.bottom += length
    layout.insets?.trailing += length

    return ModifiedContent(content: content, modifier: layout)
  }
}
