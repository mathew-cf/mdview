// swift-tools-version: 5.9
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
        )
    ]
)
