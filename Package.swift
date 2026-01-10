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
            dependencies: ["WhisperCpp"],
            path: "Sources/WhisperMac"
        ),
        .target(
            name: "WhisperCpp",
            dependencies: [],
            path: "Sources/WhisperCpp",
            exclude: [
                "metal",
                "src/llamafile",
                "src/ggml-amx",
                "src/sgemm.cpp",
                "src/sgemm.h"
            ],
            sources: ["src"],
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("include"),
                .headerSearchPath("src"),
                .define("GGML_USE_ACCELERATE"),
                .define("GGML_USE_METAL"),
                .define("ACCELERATE_NEW_LAPACK"),
                .define("ACCELERATE_LAPACK_ILP64"),
                .unsafeFlags([
                    "-fno-objc-arc",
                    "-Wno-shorten-64-to-32",
                    "-Wno-implicit-int-conversion",
                    "-Wno-unused-function",
                    "-Wno-unused-variable",
                    "-Wno-deprecated-declarations"
                ]),
            ],
            cxxSettings: [
                .headerSearchPath("include"),
                .headerSearchPath("src"),
                .define("GGML_USE_ACCELERATE"),
                .define("GGML_USE_METAL"),
                .unsafeFlags([
                    "-Wno-shorten-64-to-32",
                    "-Wno-implicit-int-conversion",
                    "-Wno-unused-function",
                    "-Wno-unused-variable",
                    "-Wno-deprecated-declarations"
                ]),
            ],
            linkerSettings: [
                .linkedFramework("Accelerate"),
                .linkedFramework("Metal"),
                .linkedFramework("MetalKit"),
                .linkedFramework("Foundation")
            ]
        )
    ],
    cxxLanguageStandard: .cxx17
)
