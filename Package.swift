// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ServerPulse",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/orlandos-nl/Citadel.git", from: "0.7.0"),
        .package(url: "https://github.com/migueldeicaza/SwiftTerm.git", from: "1.2.0"),
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.1.0"),
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.2"),
    ],
    targets: [
        .executableTarget(
            name: "ServerPulse",
            dependencies: [
                "Citadel",
                "SwiftTerm",
                .product(name: "Collections", package: "swift-collections"),
                "KeychainAccess",
            ],
            path: "ServerPulse",
            resources: [
                .copy("Resources/Localization"),
                .copy("Resources/QRCodes"),
                .copy("Resources/AppIcon.icns")
            ]
        ),
        .testTarget(
            name: "ServerPulseTests",
            dependencies: ["ServerPulse"],
            path: "ServerPulseTests"
        ),
    ]
)
