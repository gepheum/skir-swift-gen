// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "e2e-test",
    targets: [
        .executableTarget(
            name: "e2e-test",
            path: "Sources"
        ),
        .testTarget(
            name: "e2e-testTests",
            dependencies: ["e2e-test"],
            path: "Tests"
        ),
    ]
)
