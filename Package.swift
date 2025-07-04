// swift-tools-version: 6.1
import PackageDescription

let package = Package(
  name: "ShakeFeedbackKit",
  platforms: [ .iOS(.v15) ],

  // MARK: – Products
  products: [
    .library(name: "ShakeFeedbackKit", targets: ["ShakeFeedbackKit"])
  ],
  
  // MARK: – External dependencies
  dependencies: [
    // No external dependencies for now
  ],

  // MARK: – Targets
  targets: [
    .target(
      name: "ShakeFeedbackKit",
      dependencies: [
        // No dependencies for now
      ],
      resources: [.process("Resources")]
    )
    /* Uncomment later if/when you add unit tests
    , .testTarget(
        name: "ShakeFeedbackKitTests",
        dependencies: ["ShakeFeedbackKit"])
    */
  ]
)
