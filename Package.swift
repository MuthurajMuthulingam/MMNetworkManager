// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MMNetworkManager",
    platforms: [
        .iOS(.v17)
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
    ]
)
