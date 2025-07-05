# ShakeFeedbackKit

A Swift package that enables easy integration of a shake-to-feedback system in iOS apps, with Jira integration for bug reporting and feedback collection.

## Features

- 📱 Detect device shake gestures in both UIKit and SwiftUI apps
- 📸 Automatically capture screenshots when feedback is triggered
- 📝 Allow users to add notes to their feedback
- 🔄 Seamlessly integrate with Jira to create issues directly from your app
- 📊 Include device metadata with each report (OS version, app version, device model, etc.)
- ✨ Modern Swift API with async/await support

## Requirements

- iOS 15.0+
- Swift 6.0+
- Xcode 15.0+

## Installation

### Swift Package Manager

Add ShakeFeedbackKit to your project using Swift Package Manager:

1. In Xcode, select File > Add Packages...
2. Enter the repository URL: `https://github.com/yourusername/ShakeFeedbackKit.git`
3. Select the version you want to use

Alternatively, add it as a dependency in your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/ShakeFeedbackKit.git", from: "1.0.0")
]
```

## Usage

### Basic Setup

Initialize the ShakeFeedbackKit in your app delegate or at app startup:

```swift
import ShakeFeedbackKit

// In your app initialization code (e.g., app delegate or App struct)
ShakeFeedback.start(
    jiraDomain: "your-domain.atlassian.net",
    email: "your-jira-email@example.com",
    apiToken: "your-jira-api-token",
    projectKey: "YOUR_PROJECT"
)
```

### With Custom Issue Type ID

If you need to specify a custom Jira issue type ID:

```swift
ShakeFeedback.start(
    jiraDomain: "your-domain.atlassian.net",
    email: "your-jira-email@example.com",
    apiToken: "your-jira-api-token",
    projectKey: "YOUR_PROJECT",
    issueTypeId: "10004"  // Custom issue type ID
)
```

### Security Note

It's recommended to store your Jira API token securely and not hardcode it in your application. Consider using environment variables, secure storage, or a backend service to provide the token at runtime.

## How It Works

When a user shakes their device:

1. ShakeFeedbackKit detects the motion event
2. A screenshot is automatically captured
3. A feedback form is presented to the user
4. The user can add notes to accompany their feedback
5. The feedback is submitted to Jira as a new issue with the screenshot attached
6. A confirmation toast is shown to the user

## Advanced Usage

### Using the Notification System

You can also listen for shake events directly:

```swift
import Combine
import ShakeFeedbackKit

// Set up a subscriber to listen for shake events
let cancellable = NotificationCenter.default
    .publisher(for: .deviceDidShake)
    .sink { _ in
        // Custom handling when shake is detected
        print("Device was shaken!")
    }

// Remember to store the cancellable reference
```

## License

ShakeFeedbackKit is available under the MIT license. See the LICENSE file for more info.
