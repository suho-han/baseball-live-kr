// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "KboLiveCore",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "KboLiveCore",
            targets: ["KboLiveCore"]
        )
    ],
    targets: [
        .target(
            name: "KboLiveCore"
        ),
        .testTarget(
            name: "KboLiveCoreTests",
            dependencies: ["KboLiveCore"],
            resources: [
                .process("Fixtures")
            ]
        )
    ]
)
