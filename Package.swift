// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "dmn",
    products: [
        .executable(name: "dmn", targets: ["dmn"]),
        .executable(name: "current", targets: ["current"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(name: "IsDark"),
        .executableTarget(
            name: "dmn",
            dependencies: [
                .target(name: "IsDark"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]),
        .executableTarget(
            name: "current",
            dependencies: [
                .target(name: "IsDark"),
            ])
    ]
)
