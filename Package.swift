// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "mysql-backup-swift",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .executable(name: "mysql-backup-swift", targets: ["mysql-backup-swift"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "mysql-backup-core",
            dependencies: []
        ),
        .target(
            name: "mysql-backup-swift",
            dependencies: [
                "mysql-backup-core"
            ]
        ),
        .testTarget(
            name: "mysql-backup-swiftTests",
            dependencies: ["mysql-backup-core"]
        ),
    ]
)
