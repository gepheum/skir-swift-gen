// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "e2e-test",
    platforms: [.macOS(.v12)],
    targets: [
        .target(
            name: "SkirClient",
            path: "SkirClient"
        ),
        .executableTarget(
            name: "e2e-test",
            dependencies: ["SkirClient"],
            path: "Sources"
        ),
        .testTarget(
            name: "e2e-testTests",
            dependencies: ["e2e-test", "SkirClient"],
            path: "Tests"
        ),
    ]
)
