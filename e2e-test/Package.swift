// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "e2e-test",
    platforms: [.macOS(.v12)],
    dependencies: [
        .package(
            url: "https://github.com/gepheum/skir-swift-client",
            branch: "main"
        ),
    ],
    targets: [
        .executableTarget(
            name: "e2e-test",
            dependencies: [
                .product(name: "SkirClient", package: "skir-swift-client"),
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "e2e-testTests",
            dependencies: [
                "e2e-test",
                .product(name: "SkirClient", package: "skir-swift-client"),
            ],
            path: "Tests"
        ),
    ]
)
