// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "OpenVoicy",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "OpenVoicyLib",
            targets: ["OpenVoicyLib"]),
    ],
    dependencies: [
        .package(url: "https://github.com/argmaxinc/WhisperKit", from: "0.9.0"),
        .package(url: "https://github.com/ml-explore/mlx-swift", from: "0.25.4"),
        .package(url: "https://github.com/ml-explore/mlx-swift-examples", from: "2.25.4"),
    ],
    targets: [
        .target(
            name: "OpenVoicyLib",
            dependencies: [
                "WhisperKit",
                .product(name: "MLX", package: "mlx-swift"),
                .product(name: "MLXLLM", package: "mlx-swift-examples"),
                .product(name: "MLXLMCommon", package: "mlx-swift-examples"),
                .product(name: "Tokenizers", package: "mlx-swift-examples"),
            ],
            path: "Sources/OpenVoicy"),
        .testTarget(
            name: "OpenVoicyTests",
            dependencies: ["OpenVoicyLib"],
            path: "Tests/OpenVoicyTests"),
    ])
