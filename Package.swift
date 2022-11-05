// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "IOSTest",
    products: [
        .library(name: "IOSTest", targets: ["IOSTest"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "IOSTest",
            dependencies: ["IOSTestFFI"]
        ),
        .binaryTarget(
            name: "IOSTestFFI",
            path: "./Sources/IOSTestFFI.xcframework"
        ),
    ]
)


