// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SoloLevelingCore",
    platforms: [.macOS(.v13), .iOS(.v17)],
    products: [.library(name: "SoloLevelingCore", targets: ["SoloLevelingCore"])],
    targets: [
        .target(name: "SoloLevelingCore", path: "SoloLeveling/Core"),
        .testTarget(name: "SoloLevelingCoreTests", dependencies: ["SoloLevelingCore"],
                    path: "Tests/SoloLevelingCoreTests")
    ]
)
