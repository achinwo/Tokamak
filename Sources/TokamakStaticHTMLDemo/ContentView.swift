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
//  Created by Carson Katri on 7/31/20.
//

import TokamakStaticHTML

struct ContentView: View {
  var body: some View {
    HStack {
      Text("Hello, world! 1")
        .foregroundColor(.blue)
      Spacer()
      Text("Hello, world! 2")
        .foregroundColor(.green)
      Text("Hello, world! 3")
        .foregroundColor(.red)
    }
    .padding()
    .background(Color.yellow)
    .animation(.easeInOut, value: 1)
  }
}
