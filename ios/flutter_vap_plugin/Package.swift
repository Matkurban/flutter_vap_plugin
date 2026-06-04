// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "flutter_vap_plugin",
    platforms: [
        .iOS("12.0"),
    ],
    products: [
        .library(name: "flutter-vap-plugin", targets: ["flutter_vap_plugin"]),
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
        .package(name: "qgvaplayer", path: "../qgvaplayer"),
    ],
    targets: [
        .target(
            name: "flutter_vap_plugin",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                .product(name: "QGVAPlayer", package: "qgvaplayer"),
            ],
            path: "Sources/flutter_vap_plugin",
            resources: [
                .process("PrivacyInfo.xcprivacy"),
            ]
        ),
    ]
)
