// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "EndgameMaster",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .executable(name: "EndgameMaster", targets: ["EndgameMaster"])
    ],
    targets: [
        .executableTarget(
            name: "EndgameMaster",
            path: ".",
            exclude: [
                "Package.swift",
                "Info.plist"
            ],
            resources: [
                .process("Resources")
            ]
        )
    ]
)

