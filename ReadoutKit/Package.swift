// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ReadoutKit",
    platforms: [.macOS("26.0")],
    products: [
        .library(name: "ReadoutCore", targets: ["ReadoutCore"])
    ],
    targets: [
        .target(name: "ReadoutCore"),
        .testTarget(name: "ReadoutCoreTests", dependencies: ["ReadoutCore"]),
    ]
)
