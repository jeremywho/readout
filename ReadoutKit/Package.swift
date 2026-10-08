// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ReadoutKit",
    platforms: [.macOS("26.0")],
    products: [
        .library(name: "ReadoutCore", targets: ["ReadoutCore"]),
        .library(name: "ReadoutSystem", targets: ["ReadoutSystem"]),
        .executable(name: "readout-probe", targets: ["readout-probe"]),
    ],
    targets: [
        .target(name: "ReadoutCore"),
        .target(
            name: "CReadout",
            linkerSettings: [.linkedFramework("IOKit"), .linkedFramework("CoreFoundation")]
        ),
        .target(
            name: "ReadoutSystem",
            dependencies: ["ReadoutCore", "CReadout"],
            linkerSettings: [.linkedFramework("SystemConfiguration")]
        ),
        .executableTarget(name: "readout-probe", dependencies: ["ReadoutSystem", "ReadoutCore"]),
        .testTarget(name: "ReadoutCoreTests", dependencies: ["ReadoutCore"]),
        .testTarget(name: "ReadoutSystemTests", dependencies: ["ReadoutSystem", "ReadoutCore", "CReadout"]),
    ]
)
