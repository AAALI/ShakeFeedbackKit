import UIKit
import SwiftUI
import PencilKit

struct FeedbackComposer: UIViewControllerRepresentable {
    let screenshot: UIImage
    let onSend: (UIImage, String) -> Void
    
    func makeUIViewController(context: Context) -> FeedbackViewController {
        FeedbackViewController(screenshot: screenshot, onSend: onSend)
    }
    
    func updateUIViewController(_ uiViewController: FeedbackViewController, context: Context) {}
}

@MainActor
class FeedbackViewController: UIViewController {
    private let screenshot: UIImage
    private let onSend: (UIImage, String) -> Void
    private var canvasView: PKCanvasView!
    private var noteTextField: UITextField!
    private var imageView: UIImageView!
    private var sendButton: UIButton!
    private var closeButton: UIButton!
    
    init(screenshot: UIImage, onSend: @escaping (UIImage, String) -> Void) {
        self.screenshot = screenshot
        self.onSend = onSend
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Report Bug"
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Send", style: .done, target: self, action: #selector(sendTapped))
        
        imageView = UIImageView(image: screenshot)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        
        canvasView = PKCanvasView()
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        canvasView.tool = PKInkingTool(.pen, color: .red, width: 4)
        canvasView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(canvasView)
        
        noteTextField = UITextField()
        noteTextField.placeholder = "Add a note..."
        noteTextField.borderStyle = .roundedRect
        noteTextField.backgroundColor = .systemBackground
        noteTextField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(noteTextField)
        
        // Add a close button
        closeButton = UIButton(type: .system)
        closeButton.setTitle("Cancel", for: .normal)
        closeButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        closeButton.backgroundColor = .systemGray5
        closeButton.setTitleColor(.label, for: .normal)
        closeButton.layer.cornerRadius = 10
        closeButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(closeButton)
        
        // Add a prominent send button
        sendButton = UIButton(type: .system)
        sendButton.setTitle("Send Feedback", for: .normal)
        sendButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        sendButton.backgroundColor = .systemBlue
        sendButton.setTitleColor(.white, for: .normal)
        sendButton.layer.cornerRadius = 10
        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sendButton)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: noteTextField.topAnchor, constant: -16),
            canvasView.topAnchor.constraint(equalTo: imageView.topAnchor),
            canvasView.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
            canvasView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
            canvasView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor),
            noteTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            noteTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            noteTextField.bottomAnchor.constraint(equalTo: sendButton.topAnchor, constant: -16),
            noteTextField.heightAnchor.constraint(equalToConstant: 44),
            
            // Layout for two buttons side by side
            closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: view.centerXAnchor, constant: -8),
            closeButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            closeButton.heightAnchor.constraint(equalToConstant: 50),
            
            sendButton.leadingAnchor.constraint(equalTo: view.centerXAnchor, constant: 8),
            sendButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            sendButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            sendButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    @objc private func cancelTapped() { dismiss(animated: true) }
    
    @objc private func sendTapped() {
        // Show loading state
        let originalTitle = sendButton.title(for: .normal)
        sendButton.setTitle("Sending...", for: .normal)
        sendButton.isEnabled = false
        
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        onSend(createAnnotatedImage(), noteTextField.text ?? "")
        
        // Add a slight delay to show the sending state before dismissing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.dismiss(animated: true)
        }
    }
    
    private func createAnnotatedImage() -> UIImage {
        UIGraphicsImageRenderer(size: screenshot.size).image { _ in
            screenshot.draw(at: .zero)
            canvasView.drawing.image(from: CGRect(origin: .zero, size: screenshot.size), scale: 1.0).draw(at: .zero)
        }
    }
}
