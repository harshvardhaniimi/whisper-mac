// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WhisperMac",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "WhisperMac",
            targets: ["WhisperMac"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "WhisperMac",
            dependencies: [],
            path: "Sources/WhisperMac",
            linkerSettings: [
                .linkedFramework("AVFoundation"),
                .linkedFramework("Speech"),
                .linkedFramework("AppKit"),
                .linkedFramework("Carbon")
            ]
        )
    ]
)
