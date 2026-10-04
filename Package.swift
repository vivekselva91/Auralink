// swift-tools-version:5.9
// Platform-independent core logic (selection math, gesture classification, push detection).
// Run `swift test` on macOS. The iOS app layer in App/ imports this package.
import PackageDescription

let package = Package(
    name: "AuraLinkCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "AuraLinkCore", targets: ["AuraLinkCore"])],
    targets: [
        .target(name: "AuraLinkCore", path: "Sources/AuraLinkCore"),
        .testTarget(name: "AuraLinkCoreTests", dependencies: ["AuraLinkCore"], path: "Tests/AuralinkCoreTests"),
    ]
)
