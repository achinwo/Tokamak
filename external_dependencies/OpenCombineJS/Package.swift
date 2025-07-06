// swift-tools-version:6.2
import PackageDescription

let package = Package(
  name: "OpenCombineJS",
  platforms: [
    .macOS(.v10_15),
    .iOS(.v13),
    .tvOS(.v13),
    .watchOS(.v6),
    .visionOS(.v1),
  ],
  products: [
    .executable(name: "OpenCombineJSExample", targets: ["OpenCombineJSExample"]),
    .library(name: "OpenCombineJS", targets: ["OpenCombineJS"]),
  ],
  dependencies: [
    .package(
      url: "https://github.com/swiftwasm/JavaScriptKit.git",
      from: "0.31.1"
    ),
    .package(url: "https://github.com/OpenCombine/OpenCombine.git", from: "0.14.0"),
  ],
  targets: [
    .executableTarget(
      name: "OpenCombineJSExample",
      dependencies: [
        "OpenCombineJS"
      ],
      swiftSettings: [
        .defaultIsolation(MainActor.self),
        .unsafeFlags(["-strict-concurrency=minimal", "-continue-building-after-errors"]),
      ]
    ),
    .target(
      name: "OpenCombineJS",
      dependencies: [
        "JavaScriptKit", "OpenCombine",
      ],
      swiftSettings: [
        .defaultIsolation(MainActor.self),
        .unsafeFlags(["-strict-concurrency=minimal", "-continue-building-after-errors"]),
      ]
    ),
  ]
)
