// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CafeVeloz",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "CafeVeloz", targets: ["CafeVeloz"])
    ],
    targets: [
        .executableTarget(
            name: "CafeVeloz",
            path: "Sources/CafeVeloz",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "CafeVelozTests",
            dependencies: ["CafeVeloz"],
            path: "Tests/CafeVelozTests"
        )
    ]
)
