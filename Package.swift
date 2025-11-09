// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "UIInspectorKit",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        // Two separate libraries you can import independently
        .library(
            name: "UIKitInspector",
            targets: ["UIKitInspector"]
        ),
        .library(
            name: "SwiftUIInspector",
            targets: ["SwiftUIInspector"]
        ),
    ],
    targets: [
        // UIKit target
        .target(
            name: "InspectCore",
            dependencies: []
        ),
        .target(
            name: "UIKitInspector",
            dependencies: ["InspectCore"],
            path: "Sources/UIKitInspector"
        ),
        
        // SwiftUI target
        .target(
            name: "SwiftUIInspector",
            dependencies: ["InspectCore"],
            path: "Sources/SwiftUIInspector"
        ),
    ]
)

