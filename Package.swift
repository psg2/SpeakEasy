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
        .package(url: "https://github.com/exPHAT/SwiftWhisper", branch: "master")
    ],
    targets: [
        .target(
            name: "OpenVoicyLib",
            dependencies: ["SwiftWhisper"],
            path: "Sources/OpenVoicy"
        )
    ]
)
