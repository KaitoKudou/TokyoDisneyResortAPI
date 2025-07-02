// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "TokyoDisneyResortAPI",
    platforms: [
       .macOS(.v13)
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.110.1"),
        // 🔵 Non-blocking, event-driven networking for Swift. Used for custom executors
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.65.0"),
        // SwiftSoup
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.8.7"),
        // swift-dependencies
        .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.9.2"),
        // OpenAPI
        .package(url: "https://github.com/apple/swift-openapi-generator", from: "1.3.0"),
        .package(url: "https://github.com/apple/swift-openapi-runtime", from: "1.5.0"),
        .package(url: "https://github.com/swift-server/swift-openapi-vapor", from: "1.0.1"),
    ],
    targets: [
        .executableTarget(
            name: "TokyoDisneyResortAPI",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
                .product(name: "SwiftSoup", package: "SwiftSoup"),
                .product(name: "Dependencies", package: "swift-dependencies"),
                // OpenAPI
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
                .product(name: "OpenAPIVapor", package: "swift-openapi-vapor"),
            ],
            swiftSettings: swiftSettings,
            plugins: [
                .plugin(name: "OpenAPIGenerator", package: "swift-openapi-generator"),
            ]
        ),
        .testTarget(
            name: "TokyoDisneyResortAPITests",
            dependencies: [
                .target(name: "TokyoDisneyResortAPI"),
                .product(name: "VaporTesting", package: "vapor"),
            ],
            swiftSettings: swiftSettings
        )
    ]
)

var swiftSettings: [SwiftSetting] { [
    .enableUpcomingFeature("ExistentialAny"),
] }
