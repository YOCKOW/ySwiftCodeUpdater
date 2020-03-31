// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "ySwiftCodeUpdater",
  products: [
    // Products define the executables and libraries produced by a package, and make them visible to other packages.
    .library(name: "ySwiftCodeUpdater", targets: ["yCodeUpdater"]),
  ],
  dependencies: [
    // Dependencies declare other packages that this package depends on.
    .package(url: "https://github.com/YOCKOW/SwiftBonaFideCharacterSet.git", from: "1.6.2"),
    .package(url: "https://github.com/yaslab/CSV.swift.git", from: "2.4.2"),
    .package(url: "https://github.com/YOCKOW/SwiftNetworkGear.git", "0.11.0"..<"2.0.0"),
    .package(url: "https://github.com/YOCKOW/SwiftRanges.git", from: "3.1.0"),
    .package(url: "https://github.com/YOCKOW/SwiftStringComposition.git", from: "1.1.0"),
    .package(url: "https://github.com/YOCKOW/SwiftTemporaryFile.git", from: "3.2.2"),
    .package(url: "https://github.com/YOCKOW/SwiftUnicodeSupplement.git", "0.7.1"..<"2.0.0"),
    .package(url: "https://github.com/YOCKOW/ySwiftExtensions.git", "0.9.0"..<"2.0.0"),
  ],
  targets: [
    // Targets are the basic building blocks of a package. A target can define a module or a test suite.
    // Targets can depend on other targets in this package, and on products in packages which this package depends on.
    .target(name: "yCodeUpdater",
            dependencies: ["SwiftBonaFideCharacterSet",
                           "CSV",
                           "SwiftNetworkGear",
                           "SwiftRanges",
                           "SwiftStringComposition",
                           "SwiftUnicodeSupplement",
                           "SwiftTemporaryFile",
                           "ySwiftExtensions"]
    ),
    .testTarget(name: "yCodeUpdaterTests",
                dependencies: [
                  "CSV",
                  "SwiftRanges",
                  "SwiftTemporaryFile",
                  "yCodeUpdater",
                ]),
  ]
)
