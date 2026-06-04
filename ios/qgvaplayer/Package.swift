// swift-tools-version: 5.9

import Foundation
import PackageDescription

private let vapClonePath = "Sources/vap"
private let vapSourcesPath = "\(vapClonePath)/iOS/QGVAPlayer/QGVAPlayer"
private let vapTag = "iOS1.0.19"
private let vapRepo = "https://github.com/Tencent/vap.git"

/// Fetches QGVAPlayer sources from GitHub when the package manifest is evaluated.
private func cloneVapIfNeeded() {
    let marker = "\(vapSourcesPath)/Classes/QGVAPWrapView.h"
    if FileManager.default.fileExists(atPath: marker) {
        return
    }
    if FileManager.default.fileExists(atPath: vapClonePath) {
        try? FileManager.default.removeItem(atPath: vapClonePath)
    }
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
    process.arguments = [
        "clone",
        "--depth", "1",
        "--branch", vapTag,
        vapRepo,
        vapClonePath,
    ]
    do {
        try process.run()
        process.waitUntilExit()
        if process.terminationStatus != 0 {
            fputs(
                "qgvaplayer: failed to clone \(vapRepo) (tag \(vapTag)), exit \(process.terminationStatus)\n",
                stderr
            )
        }
    } catch {
        fputs("qgvaplayer: git clone error: \(error)\n", stderr)
    }
}

cloneVapIfNeeded()

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
