// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MDView",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "MDView",
            path: "Sources/MDView",
            resources: [
                .copy("Resources")
            ]
        ),
        .testTarget(
            name: "MDViewTests",
            dependencies: ["MDView"],
            path: "Tests/MDViewTests"
        )
    ]
)
