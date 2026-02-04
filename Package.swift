// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Hiyo",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        // Hiyo is a macOS app built via SPM + Xcode integration.
        // The executable target provides the app’s entry point.
        .executable(name: "Hiyo", targets: ["Hiyo"])
    ],
    dependencies: [
        // Pin exact versions for reproducible, secure builds.
        .package(url: "https://github.com/ml-explore/mlx-swift.git", exact: "0.18.0"),
        .package(url: "https://github.com/huggingface/swift-transformers.git", exact: "0.1.0")
    ],
    targets: [
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
            exclude: ["Resources/Info.plist", "Resources/Hiyo.entitlements"],
            resources: [
                // Ensures icons, prompts, configs, and other assets are bundled.
                .process("Resources")
            ],
            swiftSettings: [
                // Only enable StrictConcurrency if required by your architecture.
                // Remove this line if not strictly necessary.
                // .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        // Test target commented out as the directory structure is missing in the repository
        // .testTarget(
        //     name: "HiyoTests",
        //     dependencies: ["Hiyo"],
        //     path: "Hiyo/Tests/HiyoTests",
        //     resources: [
        //         // Allows test fixtures, sample JSON, etc.
        //         .process("Resources")
        //     ]
        // )
    ]
)
