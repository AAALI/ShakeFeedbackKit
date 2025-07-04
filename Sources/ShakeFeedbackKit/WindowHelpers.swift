import UIKit

@MainActor
extension UIView {
    /// Captures a snapshot of the view as UIImage
    func snapshotImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { context in
            layer.render(in: context.cgContext)
        }
    }
}

@MainActor
extension UIWindow {
    /// Shows a temporary toast message at the bottom center of the window
    func showShakeToast(text: String, color: UIColor) {
        let toast = UILabel()
        toast.text = text
        toast.textColor = .white
        toast.backgroundColor = color
        toast.textAlignment = .center
        toast.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        toast.layer.cornerRadius = 8
        toast.clipsToBounds = true
        toast.alpha = 0
        
        // Size and position
        toast.translatesAutoresizingMaskIntoConstraints = false
        addSubview(toast)
        
        NSLayoutConstraint.activate([
            toast.centerXAnchor.constraint(equalTo: centerXAnchor),
            toast.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -20),
            toast.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, multiplier: 0.8),
            toast.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        // Animate in and out
        UIView.animate(withDuration: 0.3, animations: {
            toast.alpha = 1.0
        }) { _ in
            UIView.animate(withDuration: 0.3, delay: 1.0, options: [], animations: {
                toast.alpha = 0.0
            }) { _ in
                toast.removeFromSuperview()
            }
        }
    }
}
