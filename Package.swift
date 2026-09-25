// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Markdown",
    platforms: [.macOS(.v26)],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", exact: "2.10.0")
    ],
    targets: [
        .executableTarget(
            name: "Markdown",
            dependencies: [.product(name: "Sparkle", package: "Sparkle")],
            path: "Sources/Markdown",
            swiftSettings: [.swiftLanguageMode(.v5)],
            linkerSettings: [.unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "@executable_path/../Frameworks"])]
        ),
    ]
)