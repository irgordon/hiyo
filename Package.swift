// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Hiyo",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "Hiyo", targets: ["Hiyo"])
    ],
    dependencies: [
        .package(url: "https://github.com/ml-explore/mlx-swift.git", from: "0.18.0"),
        .package(url: "https://github.com/huggingface/swift-transformers.git", from: "0.1.0")
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
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        )
    ]
)
