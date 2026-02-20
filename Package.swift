// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Kalam",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "Kalam",
            targets: ["Kalam"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/argmaxinc/WhisperKit.git", from: "0.9.0"),
    ],
    targets: [
        .executableTarget(
            name: "Kalam",
            dependencies: [
                .product(name: "WhisperKit", package: "WhisperKit"),
            ],
            path: "Sources/Kalam",
            linkerSettings: [
                .linkedFramework("AVFoundation"),
                .linkedFramework("AppKit"),
                .linkedFramework("Carbon")
            ]
        )
    ]
)
