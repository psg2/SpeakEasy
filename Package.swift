// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "OpenVoicy",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "OpenVoicyLib",
            targets: ["OpenVoicyLib"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/argmaxinc/WhisperKit", from: "0.9.0")
    ],
    targets: [
        .target(
            name: "OpenVoicyLib",
            dependencies: ["WhisperKit"],
            path: "Sources/OpenVoicy"
        )
    ]
)
