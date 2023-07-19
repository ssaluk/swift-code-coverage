// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CodeCoverage",
    platforms: [
        .macOS(.v12),
    ],
    products: [
        .executable(name: "codecoverage",
                    targets: ["CodeCoverage"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
        .package(url: "https://github.com/davidahouse/XCResultKit", from: "1.0.2"),
        .package(url: "https://github.com/jpsim/Yams", from: "5.0.5"),
        .package(url: "https://github.com/scottrhoyt/SwiftyTextTable.git", from: "0.9.0")
    ],
    targets: [
        .executableTarget(
            name: "CodeCoverage",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "XCResultKit", package: "XCResultKit"),
                .product(name: "Yams", package: "Yams"),
                .product(name: "SwiftyTextTable", package: "SwiftyTextTable")
            ],
            path: "Sources"
        )
    ]
)
