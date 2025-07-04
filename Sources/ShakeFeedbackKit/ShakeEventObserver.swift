import UIKit
import Combine

/// Observer that detects device shake events without replacing the main window
@MainActor
class ShakeEventObserver: NSObject {
    /// Handler to be called when a shake gesture is detected
    var shakeHandler: (() -> Void)?
    private var notificationToken: NSObjectProtocol?
    
    override init() {
        super.init()
        setupNotifications()
        extendUIWindowForShakeDetection()
    }
    
    deinit {
        if let token = notificationToken {
            NotificationCenter.default.removeObserver(token)
        }
    }
    
    private func setupNotifications() {
        // Register for shake notifications
        notificationToken = NotificationCenter.default.addObserver(
            forName: .deviceDidShake,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.shakeHandler?()
        }
    }
    
    private func extendUIWindowForShakeDetection() {
        // We need to swizzle UIWindow's motionEnded method to detect shake gestures
        // This is only necessary if it hasn't been done already
        let originalSelector = #selector(UIWindow.motionEnded(_:with:))
        let swizzledSelector = #selector(UIWindow.swizzled_motionEnded(_:with:))
        
        let originalMethod = class_getInstanceMethod(UIWindow.self, originalSelector)
        let swizzledMethod = class_getInstanceMethod(UIWindow.self, swizzledSelector)
        
        // Check if our category extension has already been applied
        if let originalMethod = originalMethod, let swizzledMethod = swizzledMethod {
            // Add our swizzled method if it hasn't been added yet
            let didAddMethod = class_addMethod(
                UIWindow.self,
                originalSelector,
                method_getImplementation(swizzledMethod),
                method_getTypeEncoding(swizzledMethod)
            )
            
            if didAddMethod {
                class_replaceMethod(
                    UIWindow.self,
                    swizzledSelector,
                    method_getImplementation(originalMethod),
                    method_getTypeEncoding(originalMethod)
                )
            } else {
                method_exchangeImplementations(originalMethod, swizzledMethod)
            }
        }
    }
}

// Define the notification name for shake events
extension Notification.Name {
    static let deviceDidShake = Notification.Name("deviceDidShakeNotification")
}

// Extension to UIWindow to detect shake gestures
extension UIWindow {
    @objc func swizzled_motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        // Call the original implementation
        self.swizzled_motionEnded(motion, with: event)
        
        // If it's a shake motion, post a notification
        if motion == .motionShake {
            print("ShakeFeedbackKit: Shake gesture detected")
            NotificationCenter.default.post(name: .deviceDidShake, object: nil)
        }
    }
}
