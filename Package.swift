// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "SwiftVan",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "SwiftVan",
            targets: ["SwiftVan"]
        ),
        .executable(
            name: "SwiftVanExample",
            targets: ["SwiftVanExample"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftwasm/JavaScriptKit.git", from: "0.36.0"),
    ],
    targets: [
        .target(
            name: "SwiftVan",
            dependencies: [
                .product(name: "JavaScriptKit", package: "JavaScriptKit"),
            ],
            path: "Sources/SwiftVan"
        ),
        .executableTarget(
            name: "SwiftVanExample",
            dependencies: ["SwiftVan", .product(name: "JavaScriptKit", package: "JavaScriptKit")],
            path: "Sources/SwiftVanExample"
        ),
    ]
)

