# ShakeFeedbackKit

A powerful Swift package that enables easy integration of a shake-to-feedback system in iOS apps, with advanced annotation capabilities and Jira integration for comprehensive bug reporting and feedback collection.

## Features

### 🎯 Core Functionality
- 📱 Detect device shake gestures in both UIKit and SwiftUI apps
- 📸 Automatically capture screenshots when feedback is triggered
- 📝 Allow users to add notes to their feedback
- 🔄 Seamlessly integrate with Jira to create issues directly from your app
- 📊 Include device metadata with each report (OS version, app version, device model, etc.)
- ✨ Modern Swift API with async/await support

### 🎨 Advanced Annotation System
- **🖊️ Drawing Tools**: Pen and highlighter tools for precise annotations
- **🎨 Color Picker**: 6 predefined colors (Red, Blue, Green, Orange, Purple, Black)
- **💾 Persistent State**: Annotations persist across sessions - edit anytime!
- **↩️ Comprehensive Undo**: Undo functionality for all annotations (current + previous sessions)
- **🗑️ Clear All**: Clear all annotations with confirmation dialog
- **⚡ Instant Feedback**: Immediate visual feedback with auto-navigation fallback
- **📐 Smart Scaling**: Annotations properly scale with screenshot dimensions

## Requirements

- iOS 15.0+
- Swift 6.0+
- Xcode 15.0+

## Installation

### Swift Package Manager

Add ShakeFeedbackKit to your project using Swift Package Manager:

1. In Xcode, select File > Add Packages...
2. Enter the repository URL: `https://github.com/AAALI/ShakeFeedbackKit.git`
3. Select the version you want to use

Alternatively, add it as a dependency in your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/AAALI/ShakeFeedbackKit.git", from: "1.1.0")
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

1. **Shake Detection**: ShakeFeedbackKit detects the motion event
2. **Screenshot Capture**: A screenshot is automatically captured
3. **Feedback Form**: A feedback form is presented with the screenshot preview
4. **Text Input**: The user can add notes to describe the issue
5. **Annotation (Optional)**: Tap "📝 Add Annotations" to:
   - Draw with pen or highlighter tools
   - Choose from 6 colors (Red, Blue, Green, Orange, Purple, Black)
   - Undo individual strokes or clear all annotations
   - Annotations persist across sessions for editing
6. **Submit**: The feedback is submitted to Jira as a new issue with annotated screenshot
7. **Confirmation**: A success toast is shown to the user

### 🎨 Annotation Workflow

The annotation system provides a seamless experience:

- **Persistent Editing**: Annotations are saved automatically - you can exit and return to continue editing
- **Smart Undo**: Undo button works for all annotations, even from previous sessions
- **Clear All**: Bin icon clears all annotations with confirmation dialog
- **Visual Feedback**: Immediate clearing or auto-navigation ensures smooth UX
- **Tool Selection**: Switch between pen (precise drawing) and highlighter (broader strokes)
- **Color Variety**: 6 carefully chosen colors for different annotation needs

## 🎨 Annotation Features in Detail

### Drawing Tools

**Pen Tool** 🖊️
- Perfect for precise annotations, arrows, and detailed markings
- 4pt line width for clear visibility
- Ideal for pointing out specific UI elements or bugs

**Highlighter Tool** 🖍️
- Broader 20pt width with 60% opacity for highlighting areas
- Great for marking sections, regions, or general areas of interest
- Semi-transparent to preserve underlying screenshot details

### Color Options

Choose from 6 carefully selected colors:
- 🔴 **Red**: Critical issues, errors, bugs
- 🔵 **Blue**: Information, notes, suggestions
- 🟢 **Green**: Positive feedback, working features
- 🟠 **Orange**: Warnings, improvements needed
- 🟣 **Purple**: Questions, unclear behavior
- ⚫ **Black**: General annotations, neutral marking

### Annotation Persistence

```swift
// Annotations are automatically saved when you:
// 1. Switch tools or colors
// 2. Tap "Done" to return to feedback form
// 3. Exit the annotation view

// When you return to annotate the same screenshot:
// - All previous annotations are restored
// - You can continue editing where you left off
// - Undo works for both new and previous annotations
```

### Best Practices

1. **Use Red for Critical Issues**: Mark bugs, crashes, or broken functionality
2. **Use Blue for Information**: Add explanatory notes or context
3. **Use Highlighter for Areas**: Mark general regions rather than specific points
4. **Use Pen for Precision**: Point to exact UI elements or text
5. **Combine Tools**: Use both pen and highlighter for comprehensive feedback

### Example Annotation Workflows

**Bug Report**:
1. Use red pen to circle the problematic UI element
2. Use blue pen to draw an arrow pointing to the issue
3. Add text description: "Button doesn't respond to taps"

**Feature Request**:
1. Use orange highlighter to mark the area for improvement
2. Use blue pen to sketch the desired change
3. Add text description: "Add search functionality here"

**UI Feedback**:
1. Use purple highlighter to mark confusing sections
2. Use green pen to mark what works well
3. Add comprehensive text feedback

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

## 🛠️ Troubleshooting

### Common Issues

**Annotations not persisting**
- Ensure you tap "Done" to save annotations before exiting
- Annotations are tied to the specific screenshot - new screenshots start fresh

**Shake detection not working**
- Make sure you've called `ShakeFeedback.start()` during app initialization
- Test on a physical device - shake detection doesn't work in simulator
- Check that your app has motion permissions if required

**Jira integration issues**
- Verify your Jira domain, email, and API token are correct
- Ensure the project key exists and you have permission to create issues
- Check that the issue type ID is valid for your project

### Performance Tips

- **Memory Management**: ShakeFeedbackKit automatically manages annotation data
- **Storage**: Annotations are stored efficiently using serialized data structures
- **UI Performance**: Drawing is optimized for smooth real-time annotation

## 📱 Example Integration

### SwiftUI App

```swift
import SwiftUI
import ShakeFeedbackKit

@main
struct MyApp: App {
    init() {
        // Initialize ShakeFeedbackKit
        ShakeFeedback.start(
            jiraDomain: "mycompany.atlassian.net",
            email: "feedback@mycompany.com",
            apiToken: ProcessInfo.processInfo.environment["JIRA_TOKEN"] ?? "",
            projectKey: "MOBILE"
        )
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### UIKit App

```swift
import UIKit
import ShakeFeedbackKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Initialize ShakeFeedbackKit
        ShakeFeedback.start(
            jiraDomain: "mycompany.atlassian.net",
            email: "feedback@mycompany.com",
            apiToken: getSecureAPIToken(), // Implement secure token retrieval
            projectKey: "MOBILE",
            issueTypeId: "10004" // Optional: specify custom issue type
        )
        
        return true
    }
    
    private func getSecureAPIToken() -> String {
        // Implement secure token retrieval from keychain or secure storage
        return "your-secure-token"
    }
}
```

### Custom Shake Handling

```swift
import Combine
import ShakeFeedbackKit

class FeedbackManager: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Listen for shake events
        NotificationCenter.default
            .publisher(for: .deviceDidShake)
            .sink { [weak self] _ in
                self?.handleShakeDetected()
            }
            .store(in: &cancellables)
    }
    
    private func handleShakeDetected() {
        // Custom logic before showing feedback
        print("Shake detected - preparing feedback...")
        
        // You can add custom analytics, logging, etc.
        Analytics.track("shake_feedback_triggered")
    }
}
```

## 🎯 Best Practices

### Security
- Store API tokens securely using Keychain or environment variables
- Never hardcode sensitive credentials in your source code
- Consider using a backend service to proxy Jira requests

### User Experience
- Provide clear instructions to users about the shake-to-feedback feature
- Consider adding an alternative way to access feedback (e.g., settings menu)
- Test the annotation tools thoroughly on different screen sizes

### Development
- Test on physical devices for accurate shake detection
- Verify Jira integration in development environment first
- Use descriptive project keys and issue types for better organization

## 📋 Requirements & Compatibility

- **iOS**: 15.0+
- **Swift**: 6.0+
- **Xcode**: 15.0+
- **Jira**: Cloud or Server instances with REST API access
- **Permissions**: No special permissions required

## License

ShakeFeedbackKit is available under the MIT license. See the LICENSE file for more info.
