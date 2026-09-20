// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Markdown",
    platforms: [.macOS(.v26)],
    targets: [
        .executableTarget(
            name: "Markdown",
            path: "Sources/Markdown",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
    ]
)