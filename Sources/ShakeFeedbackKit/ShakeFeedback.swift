import UIKit
import SwiftUI
import Combine

// Define the notification name for shake gestures
public extension Notification.Name {
    static public let deviceDidShake = Notification.Name("deviceDidShakeNotification")
}

/// Super simple shake detection using built-in UIKit functionality
@MainActor
public class ShakeEventObserver: NSObject {
    public var shakeHandler: (() -> Void)?
    
    // Simple controller that can detect device shaking
    private let shakeController = ShakeViewController()
    
    public override init() {
        super.init()
        shakeController.onShake = { [weak self] in
            self?.shakeHandler?()
        }
        setupShakeDetection()
    }
    
    private func setupShakeDetection() {
        // No need to do anything else - ShakeViewController handles detection
        print("ShakeFeedbackKit: Shake detection ready")
    }
}

/// Internal view controller that receives shake motion events
class ShakeViewController: UIViewController {
    var onShake: (() -> Void)?
    
    init() {
        super.init(nibName: nil, bundle: nil)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        // Create a minimal view
        view = UIView(frame: .zero)
        view.isHidden = true
        
        // Add to the root view controller when possible
        DispatchQueue.main.async { [weak self] in
            if let window = UIApplication.shared.windows.first,
               let rootVC = window.rootViewController {
                rootVC.addChild(self!)
                rootVC.view.addSubview(self!.view)
                self!.didMove(toParent: rootVC)
                self!.becomeFirstResponder()
                print("ShakeFeedbackKit: Shake detector installed")
            }
        }
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        becomeFirstResponder()
    }
    
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        super.motionEnded(motion, with: event)
        if motion == .motionShake {
            print("ShakeFeedbackKit: Shake detected")
            onShake?()
            NotificationCenter.default.post(name: .deviceDidShake, object: nil)
        }
    }
}

// Simple view controller that becomes first responder to detect shakes
class ShakeDetectionViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.isUserInteractionEnabled = false
        becomeFirstResponder()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        becomeFirstResponder()
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            print("ShakeFeedbackKit: Shake detected")
            NotificationCenter.default.post(name: .deviceDidShake, object: nil)
        }
        super.motionEnded(motion, with: event)
    }
}

/// Shake gesture feedback system compatible with both UIKit and SwiftUI apps
public enum ShakeFeedback {
    @MainActor private static var jiraClient: JiraClient?
    @MainActor private static var cancellables = Set<AnyCancellable>()
    @MainActor private static var shakeObserver: ShakeEventObserver?
    
    /// Initialize the feedback system
    /// - Parameters:
    ///   - jiraDomain: Jira domain without https:// (e.g., "yourdomain.atlassian.net")
    ///   - email: Jira account email
    ///   - apiToken: Jira API token
    ///   - projectKey: Jira project key
    ///   - issueTypeId: Jira issue type ID (default: "10004")
    @MainActor
    public static func start(
        jiraDomain: String,
        email: String,
        apiToken: String,
        projectKey: String,
        issueTypeId: String = "10004"
    ) {
        jiraClient = JiraClient(jiraDomain: jiraDomain, email: email, apiToken: apiToken, projectKey: projectKey, issueTypeId: issueTypeId)
        setupShakeDetection()
    }
    
    @MainActor
    private static func setupShakeDetection() {
        print("ShakeFeedbackKit: Setting up shake detection")
        // Use a shake observer that doesn't replace the window hierarchy
        shakeObserver = ShakeEventObserver()
        shakeObserver?.shakeHandler = {
            handleShake()
        }
    }
    
    @MainActor
    private static func handleShake() {
        guard let jiraClient = jiraClient,
              let windowScene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else { 
            print("ShakeFeedbackKit: Could not access window or root view controller")
            return 
        }
        
        // Take screenshot of current window without replacing it
        let screenshot = captureScreenshot(from: window)
        
        // Create feedback UI
        let composer = FeedbackComposer(screenshot: screenshot) { image, note in
            Task {
                do {
                    let issueKey = try await jiraClient.send(image: image, note: note)
                    await MainActor.run {
                        showToast(in: window, text: "Sent to Jira ✔︎", color: .systemGreen)
                        print("ShakeFeedbackKit: Created issue \(issueKey)")
                    }
                } catch {
                    await MainActor.run {
                        showToast(in: window, text: "Failed to send", color: .systemRed)
                        print("ShakeFeedbackKit: Failed to send - \(error)")
                    }
                }
            }
        }
        
        // Present the feedback UI over the current view hierarchy
        let hostingController = UIHostingController(rootView: composer)
        let navController = UINavigationController(rootViewController: hostingController)
        navController.modalPresentationStyle = .fullScreen
        rootViewController.present(navController, animated: true)
    }
    
    @MainActor
    private static func captureScreenshot(from window: UIWindow) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(window.bounds.size, false, UIScreen.main.scale)
        window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
    
    @MainActor
    private static func showToast(in window: UIWindow, text: String, color: UIColor) {
        let label = UILabel()
        label.backgroundColor = color
        label.textColor = .white
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.text = text
        label.alpha = 0
        label.layer.cornerRadius = 10
        label.clipsToBounds = true
        label.frame = CGRect(x: 0, y: 0, width: 200, height: 40)
        label.center = CGPoint(x: window.bounds.midX, y: window.bounds.height - 100)
        
        window.addSubview(label)
        
        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseIn, animations: {
            label.alpha = 1
        }, completion: { _ in
            UIView.animate(withDuration: 0.5, delay: 1.5, options: .curveEaseOut, animations: {
                label.alpha = 0
            }, completion: { _ in
                label.removeFromSuperview()
            })
        })
    }
}
