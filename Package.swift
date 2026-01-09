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
    dependencies: [
        // We'll manually integrate whisper.cpp as a git submodule
    ],
    targets: [
        .executableTarget(
            name: "WhisperMac",
            dependencies: ["WhisperCpp"],
            path: "Sources/WhisperMac",
            resources: [
                .process("Resources")
            ]
        ),
        .target(
            name: "WhisperCpp",
            dependencies: [],
            path: "Sources/WhisperCpp",
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("."),
                .define("GGML_USE_ACCELERATE"),
                .define("ACCELERATE_NEW_LAPACK"),
                .define("ACCELERATE_LAPACK_ILP64"),
                .unsafeFlags(["-fno-objc-arc"]),
            ],
            linkerSettings: [
                .linkedFramework("Accelerate"),
                .linkedFramework("Metal"),
                .linkedFramework("MetalKit")
            ]
        )
    ]
)
