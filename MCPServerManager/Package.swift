// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MCPServerManager",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "MCPServerManager",
            targets: ["MCPServerManager"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.5.0"),
        .package(url: "https://github.com/LebJe/TOMLKit", from: "0.6.0")
    ],
    targets: [
        .executableTarget(
            name: "MCPServerManager",
            dependencies: [
                .product(name: "Sparkle", package: "Sparkle"),
                .product(name: "TOMLKit", package: "TOMLKit")
            ],
            path: "MCPServerManager",
            exclude: ["Info.plist"],
            resources: [
                .process("Resources")
            ]
        )
    ]
)
