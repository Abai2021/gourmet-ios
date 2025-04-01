// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "gourmet-ios",
    platforms: [.iOS(.v13)],
    products: [
        .library(
            name: "gourmet-ios",
            targets: ["gourmet-ios"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "5.7.1")),
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", .upToNextMajor(from: "5.0.0")),
    ],
    targets: [
        .target(
            name: "gourmet-ios",
            dependencies: ["Alamofire", "SwiftyJSON"],
            path: "gourmet-ios"),
        .testTarget(
            name: "gourmet-iosTests",
            dependencies: ["gourmet-ios"],
            path: "gourmet-iosTests"),
    ]
)
