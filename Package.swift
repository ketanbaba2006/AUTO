// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AUTO",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "AUTO", targets: ["AUTO"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "AUTO",
            dependencies: [],
            path: "AUTO",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "AUTOTests",
            dependencies: ["AUTO"],
            path: "Tests"
        )
    ]
)
