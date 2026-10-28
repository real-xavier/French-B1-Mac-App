// swift-tools-version: 5.9
import PackageDescription
let bundledResources = [
    "Resources/vocabulary.json",
    "Resources/verbs.json",
    "Resources/provenance.json",
    "Resources/licenses"
]

let package = Package(
    name: "FrenchB1",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "FrenchB1", targets: ["FrenchB1"])
    ],
    targets: [
        .executableTarget(
            name: "FrenchB1",
            path: ".",
            exclude: ["Package.swift", "README.md", "Documentation", "Tests", "Tools", ".build", "Resources/FleLex_TT_Beacco.tsv", "Resources/morphology", "Resources/verb_metadata.json", "Resources/vocabulary_authoring", "Resources/example_translations", "Resources/AppIcon.icns", "Resources/AppIcon-1024.png"],
            sources: ["Sources/FrenchB1"],
            resources: bundledResources.map { .copy($0) }
        ),
        .testTarget(
            name: "FrenchB1Tests",
            dependencies: ["FrenchB1"],
            path: "Tests/FrenchB1Tests"
        )
    ],
    swiftLanguageVersions: [.v5]
)
