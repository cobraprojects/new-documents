// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NewDocuments",
    platforms: [.macOS(.v13)],
    targets: [
        .target(name: "NewDocumentsCore", path: "src",
                exclude: ["main.swift", "FileTypesView.swift", "FinderExtension.swift",
                          "NewDocuments-Info.plist", "NewDocumentsExtension-Info.plist", "extension.entitlements",
                          "app.entitlements", "PrivacyInfo.xcprivacy"],
                sources: ["FileTypes.swift", "MenuIcon.swift"]),
        .testTarget(name: "FileTypesTests", dependencies: ["NewDocumentsCore"])
    ]
)
