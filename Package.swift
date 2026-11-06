// swift-tools-version: 5.9
import PackageDescription

// Librerías puras y de sistema. La app de menú bar vive en CuchoVision.xcodeproj
// y depende de estos productos. Los tests cubren la lógica que no necesita hardware.
let package = Package(
    name: "CuchoVision",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "CuchoVisionCore", targets: ["CuchoVisionCore"]),
        .library(name: "HeadTracking", targets: ["HeadTracking"]),
        .library(name: "CursorOutput", targets: ["CursorOutput"]),
    ],
    targets: [
        .target(name: "CuchoVisionCore"),
        .target(
            name: "HeadTracking",
            dependencies: ["CuchoVisionCore"]
        ),
        .target(
            name: "CursorOutput",
            dependencies: ["CuchoVisionCore"]
        ),
        .testTarget(
            name: "CuchoVisionCoreTests",
            dependencies: ["CuchoVisionCore", "HeadTracking", "CursorOutput"]
        ),
    ]
)
