// swift-tools-version: 5.9

import PackageDescription

let vapSourcesPath = "../../third_party/vap/iOS/QGVAPlayer/QGVAPlayer"

let package = Package(
    name: "qgvaplayer",
    platforms: [
        .iOS("12.0"),
    ],
    products: [
        .library(name: "QGVAPlayer", targets: ["QGVAPlayer"]),
    ],
    targets: [
        .target(
            name: "QGVAPlayer",
            path: vapSourcesPath,
            exclude: [
                "Info.plist",
            ],
            resources: [
                .process("Shaders/QGHWDShaders.metal"),
            ],
            publicHeadersPath: ".",
            cSettings: [
                .headerSearchPath("."),
                .headerSearchPath("Classes"),
                .headerSearchPath("Shaders"),
            ],
            linkerSettings: [
                .linkedFramework("Metal", .when(platforms: [.iOS])),
                .linkedFramework("MetalKit", .when(platforms: [.iOS])),
                .linkedFramework("UIKit", .when(platforms: [.iOS])),
                .linkedFramework("AVFoundation", .when(platforms: [.iOS])),
                .linkedFramework("CoreVideo", .when(platforms: [.iOS])),
                .linkedFramework("QuartzCore", .when(platforms: [.iOS])),
                .linkedFramework("OpenGLES", .when(platforms: [.iOS])),
            ]
        ),
    ]
)
