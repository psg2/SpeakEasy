// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SpeakEasy",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "SpeakEasyLib",
            targets: ["SpeakEasyLib"]),
    ],
    dependencies: [
        .package(url: "https://github.com/argmaxinc/WhisperKit", from: "0.9.0"),
    ],
    targets: [
        .target(
            name: "SpeakEasyLib",
            dependencies: ["WhisperKit"],
            path: "Sources/SpeakEasy"),
        .testTarget(
            name: "SpeakEasyTests",
            dependencies: ["SpeakEasyLib"],
            path: "Tests/SpeakEasyTests"),
    ])
