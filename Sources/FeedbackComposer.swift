import SwiftUI
import PencilKit
import UIKit

/// A full-screen view that lets the tester draw on a screenshot and add a note,
/// then hands the annotated image + text back to the caller.
struct FeedbackComposer: UIViewControllerRepresentable {
  /// Callback delivers (annotatedImage, note)
  let onSend: (UIImage, String) -> Void

  func makeUIViewController(context: Context) -> VC { VC(onSend: onSend) }
  func updateUIViewController(_ vc: VC, context: Context) {}

  final class VC: UIViewController {
    private let onSend: (UIImage, String) -> Void
    private let canvas = PKCanvasView(frame: .zero)
    private let textField = UITextField(frame: .zero)

    init(onSend: @escaping (UIImage, String) -> Void) {
      self.onSend = onSend
      super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
      super.viewDidLoad()
      view.backgroundColor = .systemBackground

      // Drawing canvas
      canvas.tool = PKInkingTool(.pen, color: .systemRed, width: 4)
      canvas.drawingPolicy = .anyInput
      canvas.translatesAutoresizingMaskIntoConstraints = false
      view.addSubview(canvas)

      // Note field
      textField.placeholder = "Quick note…"
      textField.borderStyle = .roundedRect
      textField.translatesAutoresizingMaskIntoConstraints = false
      view.addSubview(textField)

      // Auto-layout
      NSLayoutConstraint.activate([
        canvas.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
        canvas.leadingAnchor.constraint(equalTo: view.leadingAnchor),
        canvas.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        canvas.bottomAnchor.constraint(equalTo: textField.topAnchor, constant: -8),

        textField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
        textField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
        textField.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                                          constant: -16)
      ])

      // “Send” button
      navigationItem.rightBarButtonItem = UIBarButtonItem(
        title: "Send", style: .done, target: self, action: #selector(send))
    }

    @objc private func send() {
      // Ensure the hierarchy is laid out before taking the shot
      view.layoutIfNeeded()

      let renderer = UIGraphicsImageRenderer(size: view.bounds.size)
      let shot = renderer.image { _ in
        view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
      }

      onSend(shot, textField.text ?? "")
      dismiss(animated: true)

      // Micro-UX: haptic + toast so the tester knows it fired
      UINotificationFeedbackGenerator().notificationOccurred(.success)
      view.window?.showShakeToast()
    }
  }
}