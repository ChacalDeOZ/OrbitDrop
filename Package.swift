// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "OrbitDrop",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "OrbitDropApp", targets: ["OrbitDropApp"]),
        .library(name: "OrbitDropKit", targets: ["OrbitDropKit"])
    ],
    targets: [
        .target(
            name: "OrbitDropKit",
            dependencies: [],
            path: "Sources/OrbitDropKit"
        ),
        .executableTarget(
            name: "OrbitDropApp",
            dependencies: ["OrbitDropKit"],
            path: "Sources/OrbitDropApp"
        ),
        .testTarget(
            name: "OrbitDropKitTests",
            dependencies: ["OrbitDropKit"],
            path: "Tests/OrbitDropKitTests"
        )
    ]
)
