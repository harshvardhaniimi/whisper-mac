// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Kalam",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "Kalam",
            targets: ["Kalam"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "Kalam",
            dependencies: [],
            path: "Sources/Kalam",
            linkerSettings: [
                .linkedFramework("AVFoundation"),
                .linkedFramework("Speech"),
                .linkedFramework("AppKit"),
                .linkedFramework("Carbon")
            ]
        )
    ]
)
