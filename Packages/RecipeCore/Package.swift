// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "RecipeCore",
    platforms: [.iOS(.v17), .macOS(.v13)],
    products: [.library(name: "RecipeCore", targets: ["RecipeCore"])],
    targets: [
        .target(name: "RecipeCore"),
        .testTarget(name: "RecipeCoreTests", dependencies: ["RecipeCore"])
    ],
    swiftLanguageVersions: [.v5]
)
