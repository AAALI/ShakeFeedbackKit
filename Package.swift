// swift-tools-version: 6.1
import PackageDescription

let package = Package(
  name: "ShakeFeedbackKit",
  platforms: [ .iOS(.v15) ],
  
  // Package description and metadata
  products: [
    .library(
      name: "ShakeFeedbackKit",
      targets: ["ShakeFeedbackKit"]
    )
  ],
  
  // Package repository and documentation links
  // These will need to be updated with your actual GitHub repository URL
  dependencies: [
    // No external dependencies for now
  ],

  // Target specification
  targets: [
    .target(
      name: "ShakeFeedbackKit",
      dependencies: [
        // No dependencies for now
      ],
      resources: [.process("Resources")],
      swiftSettings: [
        .define("DEBUG", .when(configuration: .debug))
      ]
    ),
    // Uncomment when you're ready to add tests
    // .testTarget(
    //   name: "ShakeFeedbackKitTests",
    //   dependencies: ["ShakeFeedbackKit"]
    // )
  ]
)
