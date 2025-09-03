// swift-tools-version: 5.7
import PackageDescription

let package = Package(
  name: "centerd",
  platforms: [.macOS(.v11)],
  products: [
    .executable(name: "centerd", targets: ["centerd"])
  ],
  dependencies: [],
  targets: [
    .executableTarget(
      name: "centerd",
      dependencies: []
    )
  ]
)
