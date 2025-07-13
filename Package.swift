// swift-tools-version:6.2

import PackageDescription

let package = Package(
  name: "Tokamak",
  platforms: [
    .macOS("15.4"),
    .iOS(.v15),
  ],
  products: [
    // Products define the executables and libraries produced by a package,
    // and make them visible to other packages.
    .executable(
      name: "TokamakDemo",
      targets: ["TokamakDemo"]
    ),
    .library(
      name: "TokamakDOM",
      targets: ["TokamakDOM"]
    ),
    .library(
      name: "TokamakStaticHTML",
      targets: ["TokamakStaticHTML"]
    ),
    .executable(
      name: "TokamakStaticHTMLDemo",
      targets: ["TokamakStaticHTMLDemo"],
    ),
    .library(
      name: "TokamakGTK",
      targets: ["TokamakGTK"]
    ),
    .executable(
      name: "TokamakGTKDemo",
      targets: ["TokamakGTKDemo"]
    ),
    .library(
      name: "TokamakShim",
      targets: ["TokamakShim"]
    ),
    .executable(
      name: "TokamakStaticHTMLBenchmark",
      targets: ["TokamakStaticHTMLBenchmark"]
    ),
  ],
  dependencies: [
    .package(
      url: "https://github.com/swiftwasm/JavaScriptKit.git",
      from: "0.31.1"
    ),
    .package(
      url: "https://github.com/OpenCombine/OpenCombine.git",
      from: "0.14.0"
    ),
    .package(
      path: "./external_dependencies/OpenCombineJS"
    ),
    .package(
      url: "https://github.com/google/swift-benchmark",
      from: "0.1.2"
    ),
    .package(
      url: "https://github.com/pointfreeco/swift-snapshot-testing.git",
      from: "1.9.0"
    ),
    .package(
      url: "https://github.com/swiftlang/swift-foundation.git",
      branch: "main"
    ),
    .package(
      path: "./external_dependencies/carton"
    ),
  ],
  targets: [
    // Targets are the basic building blocks of a package. A target can define
    // a module or a test suite.
    // Targets can depend on other targets in this package, and on products
    // in packages which this package depends on.
    .target(
      name: "Foundation",
      dependencies: [
        .product(
          name: "FoundationEssentials",
          package: "swift-foundation"
        )
      ],
      swiftSettings: [
        .defaultIsolation(MainActor.self)
      ]
    ),
    .target(
      name: "TokamakCore",
      dependencies: [
        .product(
          name: "OpenCombineShim",
          package: "OpenCombine"
        ),
        .target(
          name: "Foundation",
          condition: .when(platforms: [.wasi])
        ),
      ],
      swiftSettings: [
        .defaultIsolation(MainActor.self)
      ]
    ),
    .target(
      name: "TokamakShim",
      dependencies: [
        .target(
          name: "TokamakDOM"
        ),
        .target(
          name: "Foundation",
          condition: .when(platforms: [.wasi])
        ),
      ],
      swiftSettings: [
        .defaultIsolation(MainActor.self)
      ]
    ),
    .systemLibrary(
      name: "CGTK",
      pkgConfig: "gtk+-3.0",
      providers: [
        .apt(["libgtk+-3.0", "gtk+-3.0"]),
        // .yum(["gtk3-devel"]),
        .brew(["gtk+3"]),
      ]
    ),
    .systemLibrary(
      name: "CGDK",
      pkgConfig: "gdk-3.0",
      providers: [
        .apt(["libgtk+-3.0", "gtk+-3.0"]),
        // .yum(["gtk3-devel"]),
        .brew(["gtk+3"]),
      ]
    ),
    .target(
      name: "TokamakGTKCHelpers",
      dependencies: ["CGTK"]
    ),
    .target(
      name: "TokamakGTK",
      dependencies: [
        "TokamakCore", "CGTK", "CGDK", "TokamakGTKCHelpers",
        .product(
          name: "OpenCombineShim",
          package: "OpenCombine"
        ),
      ]
    ),
    .executableTarget(
      name: "TokamakGTKDemo",
      dependencies: ["TokamakGTK"],
      resources: [.copy("logo-header.png")]
    ),
    .target(
      name: "TokamakStaticHTML",
      dependencies: [
        "TokamakCore"
      ],
      swiftSettings: [
        .defaultIsolation(MainActor.self)
      ]
    ),
    .executableTarget(
      name: "TokamakCoreBenchmark",
      dependencies: [
        .product(
          name: "Benchmark",
          package: "swift-benchmark"
        ),
        "TokamakCore",
        "TokamakTestRenderer",
      ],
      swiftSettings: [
        .defaultIsolation(MainActor.self)
      ]
    ),
    .executableTarget(
      name: "TokamakStaticHTMLBenchmark",
      dependencies: [
        .product(
          name: "Benchmark",
          package: "swift-benchmark"
        ),
        "TokamakStaticHTML",
      ],
      swiftSettings: [
        .defaultIsolation(MainActor.self)
      ]
    ),
    .target(
      name: "TokamakDOM",
      dependencies: [
        "TokamakCore",
        "TokamakStaticHTML",
        .product(
          name: "OpenCombineShim",
          package: "OpenCombine"
        ),
        .product(
          name: "JavaScriptKit",
          package: "JavaScriptKit",
        ),
        .product(
          name: "JavaScriptEventLoop",
          package: "JavaScriptKit",
        ),
        "OpenCombineJS",
      ],
      swiftSettings: [
        .defaultIsolation(MainActor.self)
      ]
    ),
    .executableTarget(
      name: "TokamakDemo",
      dependencies: [
        "TokamakShim",
        .product(
          name: "JavaScriptKit",
          package: "JavaScriptKit"
        ),
      ],
      resources: [
        .copy("logo-header.png"),
        .copy("../../JavaScriptKit_JavaScriptKit.resources"),
      ],
      swiftSettings: [
        .defaultIsolation(MainActor.self)
      ]
    ),
    .executableTarget(
      name: "TokamakStaticHTMLDemo",
      dependencies: [
        "TokamakStaticHTML"
      ],
      swiftSettings: [
        .defaultIsolation(MainActor.self)
      ]
    ),
    .target(
      name: "TokamakTestRenderer",
      dependencies: ["TokamakCore"],
      swiftSettings: [
        .defaultIsolation(MainActor.self)
      ]
    ),
    .testTarget(
      name: "TokamakLayoutTests",
      dependencies: [
        "TokamakCore",
        "TokamakStaticHTML",
        .product(
          name: "SnapshotTesting",
          package: "swift-snapshot-testing",
          condition: .when(platforms: [.macOS]),
        ),
      ],
      swiftSettings: [
        .defaultIsolation(MainActor.self)
      ]
    ),
    .testTarget(
      name: "TokamakReconcilerTests",
      dependencies: [
        "TokamakCore",
        "TokamakTestRenderer",
      ],
      swiftSettings: [
        .defaultIsolation(MainActor.self)
      ]
    ),
    .testTarget(
      name: "TokamakTests",
      dependencies: ["TokamakTestRenderer"],
      swiftSettings: [
        .defaultIsolation(MainActor.self)
      ]
    ),
    .testTarget(
      name: "TokamakStaticHTMLTests",
      dependencies: [
        "TokamakStaticHTML",
        .product(
          name: "SnapshotTesting",
          package: "swift-snapshot-testing",
          condition: .when(platforms: [.macOS])
        ),
      ],
      exclude: [
        "__Snapshots__",
        "RenderingTests/__Snapshots__",
      ],
      swiftSettings: [
        .defaultIsolation(MainActor.self)
      ]
    ),
  ]
)
