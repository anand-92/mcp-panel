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
    dependencies: [],
    targets: [
        .executableTarget(
            name: "MCPServerManager",
            dependencies: [],
            path: "MCPServerManager"
        )
    ]
)
