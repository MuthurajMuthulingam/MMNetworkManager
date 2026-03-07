// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "MMNetworkManager",
    platforms: [
        .iOS(.v9)
    ],
    products: [
        .library(
            name: "MMNetworkManager",
            targets: ["MMNetworkManager"]
        ),
    ],
    targets: [
        .target(
            name: "MMNetworkManager",
            path: "MMNetworkManager/Classes"
        ),
    ],
    swiftLanguageVersions: [.v4, .v4_2, .v5]
)
