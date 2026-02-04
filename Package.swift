// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Hiyo",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Hiyo", targets: ["Hiyo"])
    ],
    dependencies: [
        // Pin exact versions for reproducible, secure builds.
        .package(url: "https://github.com/ml-explore/mlx-swift.git", exact: "0.18.0"),
        .package(url: "https://github.com/huggingface/swift-transformers.git", exact: "0.1.0")
    ],
    targets: [
        // MARK: - Main App Target
        .executableTarget(
            name: "Hiyo",
            dependencies: [
                .product(name: "MLX", package: "mlx-swift"),
                .product(name: "MLXRandom", package: "mlx-swift"),
                .product(name: "MLXNN", package: "mlx-swift"),
                .product(name: "MLXOptimizers", package: "mlx-swift"),
                .product(name: "Transformers", package: "swift-transformers")
            ],
            path: "Hiyo/Sources/Hiyo",
            exclude: [
                "Resources/Info.plist"
            ],
            resources: [
                .process("Resources")
            ],
            swiftSettings: [
                // Keep StrictConcurrency only if required by your architecture.
                // .enableExperimentalFeature("StrictConcurrency")
            ],
            linkerSettings: [
                .linkedFramework("Security")
                // CryptoKit is a Swift module, not a framework — no linker entry needed.
            ]
        ),

        // MARK: - Unit Tests
        .testTarget(
            name: "HiyoTests",
            dependencies: ["Hiyo"],
            path: "Hiyo/Tests/HiyoTests",
            resources: [
                .process("Resources")
            ]
        ),

        // MARK: - UI Tests
        .testTarget(
            name: "HiyoUITests",
            dependencies: ["Hiyo"],
            path: "Hiyo/Tests/HiyoUITests",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
