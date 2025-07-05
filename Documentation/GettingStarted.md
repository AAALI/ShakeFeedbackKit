# Getting Started with ShakeFeedbackKit

This guide will help you integrate ShakeFeedbackKit into your iOS application.

## Prerequisites

Before you begin, make sure you have:

1. A Jira account with API token access
2. An iOS app with minimum iOS 15.0 support
3. Xcode 15.0 or later

## Step 1: Install the Package

Add ShakeFeedbackKit to your project using Swift Package Manager.

In Xcode:
1. Go to File > Add Packages...
2. Enter the repository URL
3. Select the version you want to use

## Step 2: Initialize the SDK

Add the following code to your app's initialization flow (e.g., AppDelegate or SwiftUI App):

```swift
import ShakeFeedbackKit

// For UIKit apps - in AppDelegate
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // Initialize ShakeFeedbackKit
    ShakeFeedback.start(
        jiraDomain: "your-domain.atlassian.net",
        email: "your-jira-email@example.com",
        apiToken: "your-jira-api-token",
        projectKey: "YOUR_PROJECT"
    )
    return true
}

// For SwiftUI apps - in App struct
@main
struct YourApp: App {
    init() {
        // Initialize ShakeFeedbackKit
        ShakeFeedback.start(
            jiraDomain: "your-domain.atlassian.net",
            email: "your-jira-email@example.com",
            apiToken: "your-jira-api-token",
            projectKey: "YOUR_PROJECT"
        )
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

## Step 3: Getting a Jira API Token

1. Log in to your Atlassian account
2. Go to https://id.atlassian.com/manage-profile/security/api-tokens
3. Click "Create API token"
4. Give your token a name (e.g., "ShakeFeedbackKit")
5. Copy the generated token

## Step 4: Securing Your API Token

Do not hardcode your Jira API token in your app. Consider these approaches:

1. Use environment variables during development
2. Store tokens securely using Apple's Keychain Services
3. Proxy the requests through your backend service

## Step 5: Testing

Once integrated, simply shake your device to trigger the feedback flow. You should see:

1. A screenshot captured automatically
2. A form to enter feedback notes
3. A success message once submitted
4. A new issue created in your Jira project

## Troubleshooting

If you encounter issues:

- Ensure your Jira credentials and project key are correct
- Check that your API token has sufficient permissions
- Verify your network connectivity
- Look for any error messages in the console logs

For more detailed debugging, check the console logs as ShakeFeedbackKit logs its actions with the prefix "ShakeFeedbackKit:".
