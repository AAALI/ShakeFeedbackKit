import UIKit
import SwiftUI

// MARK: - Annotation Data Structure

struct AnnotationData {
    let points: [CGPoint]
    let color: UIColor
    let width: CGFloat
    
    func toBezierPath() -> UIBezierPath {
        let path = UIBezierPath()
        guard !points.isEmpty else { return path }
        
        path.move(to: points[0])
        for i in 1..<points.count {
            path.addLine(to: points[i])
        }
        return path
    }
    
    static func fromBezierPath(_ path: UIBezierPath, color: UIColor, width: CGFloat) -> AnnotationData {
        var points: [CGPoint] = []
        
        // Use a more reliable method to extract points
        let pathRef = path.cgPath
        pathRef.applyWithBlock { elementPtr in
            let element = elementPtr.pointee
            switch element.type {
            case .moveToPoint:
                points.append(element.points[0])
            case .addLineToPoint:
                points.append(element.points[0])
            case .addQuadCurveToPoint:
                points.append(element.points[1]) // End point of curve
            case .addCurveToPoint:
                points.append(element.points[2]) // End point of curve
            case .closeSubpath:
                break
            @unknown default:
                break
            }
        }
        
        return AnnotationData(points: points, color: color, width: width)
    }
}

// MARK: - Simplified Feedback Composer

struct FeedbackComposer: UIViewControllerRepresentable {
    let screenshot: UIImage
    let onSend: (UIImage, String) -> Void
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let feedbackVC = FeedbackViewController(screenshot: screenshot, onSubmit: onSend)
        let navController = UINavigationController(rootViewController: feedbackVC)
        return navController
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
}

// MARK: - Main Feedback View Controller

class FeedbackViewController: UIViewController {
    private let screenshot: UIImage
    private let onSubmit: (UIImage, String) -> Void
    
    // UI Components
    private var imageView: UIImageView!
    private var textView: UITextView!
    private var annotateButton: UIButton!
    private var sendButton: UIButton!
    
    // State
    private var feedbackText: String = ""
    private var annotatedImage: UIImage?
    private var storedAnnotations: [AnnotationData] = []
    private let originalScreenshot: UIImage // Keep reference to original
    
    init(screenshot: UIImage, onSubmit: @escaping (UIImage, String) -> Void) {
        self.screenshot = screenshot
        self.originalScreenshot = screenshot // Store original reference
        self.onSubmit = onSubmit
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Report Bug"
        
        // Navigation items
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )
        
        setupImageView()
        setupTextView()
        setupButtons()
        setupConstraints()
    }
    
    private func setupImageView() {
        imageView = UIImageView(image: screenshot)
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .systemGray6
        imageView.layer.cornerRadius = 12
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
    }
    
    private func setupTextView() {
        textView = UITextView()
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.layer.borderColor = UIColor.systemGray4.cgColor
        textView.layer.borderWidth = 1
        textView.layer.cornerRadius = 8
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        textView.delegate = self
        textView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add placeholder
        textView.text = "Describe the issue you encountered..."
        textView.textColor = .placeholderText
        
        view.addSubview(textView)
    }
    
    private func setupButtons() {
        // Annotate button
        annotateButton = UIButton(type: .system)
        annotateButton.setTitle("📝 Add Annotations", for: .normal)
        annotateButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        annotateButton.backgroundColor = .systemBlue
        annotateButton.setTitleColor(.white, for: .normal)
        annotateButton.layer.cornerRadius = 8
        annotateButton.addTarget(self, action: #selector(annotateTapped), for: .touchUpInside)
        annotateButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(annotateButton)
        
        // Send button
        sendButton = UIButton(type: .system)
        sendButton.setTitle("Send Feedback", for: .normal)
        sendButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        sendButton.backgroundColor = .systemGreen
        sendButton.setTitleColor(.white, for: .normal)
        sendButton.layer.cornerRadius = 8
        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sendButton)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Image view - flexible height with priority
            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            // Text view - below image
            textView.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 16),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            textView.heightAnchor.constraint(greaterThanOrEqualToConstant: 80),
            
            // Annotate button
            annotateButton.topAnchor.constraint(equalTo: textView.bottomAnchor, constant: 16),
            annotateButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            annotateButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            annotateButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Send button
            sendButton.topAnchor.constraint(equalTo: annotateButton.bottomAnchor, constant: 16),
            sendButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            sendButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            sendButton.heightAnchor.constraint(equalToConstant: 50),
            sendButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
        
        // Set flexible image height with lower priority to avoid conflicts
        let imageHeightConstraint = imageView.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor, multiplier: 0.35)
        imageHeightConstraint.priority = UILayoutPriority(999)
        imageHeightConstraint.isActive = true
    }
    
    // MARK: - Actions
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    @objc private func annotateTapped() {
        let annotationVC = AnnotationViewController(
            image: annotatedImage ?? screenshot,
            existingAnnotations: storedAnnotations
        ) { [weak self] annotatedImage, annotations in
            self?.annotatedImage = annotatedImage
            let convertedAnnotations = annotations.map { AnnotationData.fromBezierPath($0.path, color: $0.color, width: $0.width) }
            print("FeedbackViewController: Storing \(convertedAnnotations.count) annotations")
            for (index, annotation) in convertedAnnotations.enumerated() {
                print("Annotation \(index): \(annotation.points.count) points")
            }
            
            // Update stored annotations - this ensures clearing in UI clears storage
            self?.storedAnnotations = convertedAnnotations
            self?.imageView.image = annotatedImage
            
            // Update button text and image based on annotation count
            if convertedAnnotations.isEmpty {
                self?.annotateButton.setTitle("📝 Add Annotations", for: .normal)
                self?.imageView.image = self?.originalScreenshot // Restore original image
                self?.annotatedImage = nil // Clear annotated image
                print("FeedbackViewController: All annotations cleared - restored original image")
            } else {
                self?.annotateButton.setTitle("✅ Edit Annotations", for: .normal)
                print("FeedbackViewController: Annotations present - button shows edit state")
            }
        }
        
        let navController = UINavigationController(rootViewController: annotationVC)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true)
    }
    
    @objc private func sendTapped() {
        let finalImage = annotatedImage ?? screenshot
        let description = feedbackText.isEmpty ? "" : feedbackText
        
        onSubmit(finalImage, description)
        dismiss(animated: true)
    }
}

// MARK: - Simple Annotation View Controller

class AnnotationViewController: UIViewController {
    private let originalImage: UIImage
    private let onComplete: (UIImage, [(path: UIBezierPath, color: UIColor, width: CGFloat)]) -> Void
    private let existingAnnotations: [AnnotationData]?
    
    private var imageView: UIImageView!
    private var drawingView: SimpleDrawingView!
    private var toolsStackView: UIStackView!
    
    init(image: UIImage, existingAnnotations: [AnnotationData]? = nil, onComplete: @escaping (UIImage, [(path: UIBezierPath, color: UIColor, width: CGFloat)]) -> Void) {
        self.originalImage = image
        self.existingAnnotations = existingAnnotations
        self.onComplete = onComplete
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        title = "Add Annotations"
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(doneTapped)
        )
        
        setupImageView()
        setupDrawingView()
        setupToolbar()
        setupConstraints()
    }
    
    private func setupImageView() {
        imageView = UIImageView(image: originalImage)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
    }
    
    private func setupDrawingView() {
        // Convert AnnotationData back to UIBezierPath tuples
        let convertedAnnotations = existingAnnotations?.map { annotationData in
            let path = annotationData.toBezierPath()
            print("Converting annotation with \(annotationData.points.count) points to path, isEmpty: \(path.isEmpty)")
            return (path: path, color: annotationData.color, width: annotationData.width)
        }
        
        print("AnnotationViewController: Converting \(existingAnnotations?.count ?? 0) stored annotations")
        
        drawingView = SimpleDrawingView(existingAnnotations: convertedAnnotations)
        drawingView.backgroundColor = .clear
        drawingView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(drawingView)
    }
    
    private func setupToolbar() {
        toolsStackView = UIStackView()
        toolsStackView.axis = .horizontal
        toolsStackView.distribution = .fillEqually
        toolsStackView.spacing = 16
        toolsStackView.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        toolsStackView.layer.cornerRadius = 12
        toolsStackView.layoutMargins = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        toolsStackView.isLayoutMarginsRelativeArrangement = true
        toolsStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toolsStackView)
        
        // Red pen
        let redPenButton = createToolButton(title: "🔴", color: .systemRed)
        toolsStackView.addArrangedSubview(redPenButton)
        
        // Blue pen
        let bluePenButton = createToolButton(title: "🔵", color: .systemBlue)
        toolsStackView.addArrangedSubview(bluePenButton)
        
        // Yellow highlighter
        let highlighterButton = createToolButton(title: "🖍", color: .systemYellow)
        highlighterButton.addTarget(self, action: #selector(highlighterTapped), for: .touchUpInside)
        toolsStackView.addArrangedSubview(highlighterButton)
        
        // Undo
        let undoButton = createToolButton(title: "↶", color: .white)
        undoButton.addTarget(self, action: #selector(undoTapped), for: .touchUpInside)
        toolsStackView.addArrangedSubview(undoButton)
        
        // Clear all
        let clearButton = createToolButton(title: "🗑", color: .white)
        clearButton.addTarget(self, action: #selector(clearTapped), for: .touchUpInside)
        toolsStackView.addArrangedSubview(clearButton)
    }
    
    private func createToolButton(title: String, color: UIColor) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 24)
        button.setTitleColor(color, for: .normal)
        button.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(colorButtonTapped(_:)), for: .touchUpInside)
        return button
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Image view fills safe area
            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: toolsStackView.topAnchor, constant: -16),
            
            // Drawing view matches image view
            drawingView.topAnchor.constraint(equalTo: imageView.topAnchor),
            drawingView.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
            drawingView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
            drawingView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor),
            
            // Tools at bottom
            toolsStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            toolsStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            toolsStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            toolsStackView.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
    }
    
    @objc private func colorButtonTapped(_ sender: UIButton) {
        switch sender.titleLabel?.text {
        case "🔴":
            drawingView.setColor(.systemRed)
            drawingView.setWidth(4.0)
        case "🔵":
            drawingView.setColor(.systemBlue)
            drawingView.setWidth(4.0)
        default:
            break
        }
    }
    
    @objc private func highlighterTapped() {
        drawingView.setColor(.systemYellow.withAlphaComponent(0.6))
        drawingView.setWidth(20.0)
    }
    
    @objc private func undoTapped() {
        drawingView.undo()
    }
    
    @objc private func clearTapped() {
        let alert = UIAlertController(
            title: "Clear All Annotations",
            message: "Are you sure you want to remove all annotations? This cannot be undone.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Clear All", style: .destructive) { [weak self] _ in
            self?.recreateDrawingView()
        })
        
        present(alert, animated: true)
    }
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    @objc private func doneTapped() {
        let annotatedImage = createAnnotatedImage()
        let annotations = drawingView.getAllAnnotations()
        
        print("AnnotationViewController: Done tapped - returning \(annotations.count) annotations")
        for (index, annotation) in annotations.enumerated() {
            print("Annotation \(index): color \(annotation.color), width \(annotation.width)")
        }
        
        dismiss(animated: true) { [weak self] in
            self?.onComplete(annotatedImage, annotations)
        }
    }
    
    private func createAnnotatedImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: originalImage.size)
        return renderer.image { context in
            // Draw original image
            originalImage.draw(at: .zero)
            
            // Calculate aspect-fit rect for scaling annotations
            let imageRect = aspectFitRect(for: originalImage.size, in: imageView.bounds)
            let scaleX = originalImage.size.width / imageRect.width
            let scaleY = originalImage.size.height / imageRect.height
            
            context.cgContext.scaleBy(x: scaleX, y: scaleY)
            context.cgContext.translateBy(x: -imageRect.minX, y: -imageRect.minY)
            
            drawingView.layer.render(in: context.cgContext)
        }
    }
    
    private func recreateDrawingView() {
        print("AnnotationViewController: Recreating drawing view to clear annotations")
        
        // Remove old drawing view
        drawingView.removeFromSuperview()
        
        // Create completely new drawing view
        drawingView = SimpleDrawingView()
        drawingView.translatesAutoresizingMaskIntoConstraints = false
        drawingView.backgroundColor = UIColor.clear
        
        // Add to view hierarchy
        view.addSubview(drawingView)
        
        // Set up constraints
        NSLayoutConstraint.activate([
            drawingView.topAnchor.constraint(equalTo: imageView.topAnchor),
            drawingView.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
            drawingView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
            drawingView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor)
        ])
        
        // Force immediate layout and display update
        view.layoutIfNeeded()
        drawingView.setNeedsDisplay()
        drawingView.layoutIfNeeded()
        
        print("AnnotationViewController: Drawing view recreated - should show clean state")
        
        // Auto-navigate to main screen after a short delay if visual clearing doesn't work
        // This ensures user doesn't stay on a visually stale annotation screen
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            print("AnnotationViewController: Auto-navigating after clear to avoid visual confusion")
            self?.doneTapped()
        }
    }
    
    private func aspectFitRect(for imageSize: CGSize, in containerRect: CGRect) -> CGRect {
        let imageAspect = imageSize.width / imageSize.height
        let containerAspect = containerRect.width / containerRect.height
        
        let rect: CGRect
        if imageAspect > containerAspect {
            // Image is wider - fit to width
            let height = containerRect.width / imageAspect
            let y = containerRect.minY + (containerRect.height - height) / 2
            rect = CGRect(x: containerRect.minX, y: y, width: containerRect.width, height: height)
        } else {
            // Image is taller - fit to height
            let width = containerRect.height * imageAspect
            let x = containerRect.minX + (containerRect.width - width) / 2
            rect = CGRect(x: x, y: containerRect.minY, width: width, height: containerRect.height)
        }
        return rect
    }
}

// MARK: - Simple Drawing View

class SimpleDrawingView: UIView {
    private var paths: [(path: UIBezierPath, color: UIColor, width: CGFloat)] = []
    private var rawStrokes: [(points: [CGPoint], color: UIColor, width: CGFloat)] = []
    private var currentPath: UIBezierPath?
    private var currentStroke: [CGPoint] = []
    private var currentColor: UIColor = .systemRed
    private var currentWidth: CGFloat = 4.0
    
    init(existingAnnotations: [(path: UIBezierPath, color: UIColor, width: CGFloat)]? = nil) {
        super.init(frame: .zero)
        
        // Always start with empty arrays to ensure clean state
        self.paths = []
        self.rawStrokes = []
        
        if let existing = existingAnnotations {
            print("SimpleDrawingView: Loading \(existing.count) existing annotations...")
            
            // Load existing annotations into both paths and rawStrokes
            for (index, annotation) in existing.enumerated() {
                let copiedPath = annotation.path.copy() as! UIBezierPath
                if !copiedPath.isEmpty {
                    print("Loading annotation \(index): \(annotation.color)")
                    self.paths.append((path: copiedPath, color: annotation.color, width: annotation.width))
                    
                    // Convert path back to raw points for undo functionality
                    var points: [CGPoint] = []
                    copiedPath.cgPath.applyWithBlock { elementPtr in
                        let element = elementPtr.pointee
                        switch element.type {
                        case .moveToPoint, .addLineToPoint:
                            points.append(element.points[0])
                        default:
                            break
                        }
                    }
                    if !points.isEmpty {
                        self.rawStrokes.append((points: points, color: annotation.color, width: annotation.width))
                        print("Converted annotation \(index) to \(points.count) points")
                    }
                } else {
                    print("Skipping empty annotation \(index)")
                }
            }
            print("SimpleDrawingView: Final state - \(self.paths.count) paths, \(self.rawStrokes.count) raw strokes")
        } else {
            print("SimpleDrawingView: No existing annotations to load")
        }
        
        setupOptimizations()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupOptimizations()
    }
    
    private func setupOptimizations() {
        // Optimize drawing performance
        self.isOpaque = false
        self.clearsContextBeforeDrawing = true  // Changed to true to ensure proper clearing
        self.contentMode = .redraw
        self.backgroundColor = UIColor.clear
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        print("SimpleDrawingView: draw() called with \(paths.count) paths")
        
        // Completely clear the context and fill with transparent background
        context.clear(rect)
        context.setFillColor(UIColor.clear.cgColor)
        context.fill(rect)
        
        // Only draw if we have paths to draw
        guard !paths.isEmpty || currentPath != nil else {
            print("SimpleDrawingView: No paths to draw, context cleared")
            return
        }
        
        // Draw all stored paths
        for (index, pathInfo) in paths.enumerated() {
            print("Drawing path \(index): \(pathInfo.color)")
            context.setStrokeColor(pathInfo.color.cgColor)
            context.setLineWidth(pathInfo.width)
            context.setLineCap(.round)
            context.setLineJoin(.round)
            context.addPath(pathInfo.path.cgPath)
            context.strokePath()
        }
        
        // Draw current path if it exists
        if let currentPath = currentPath {
            print("Drawing current path")
            context.setStrokeColor(currentColor.cgColor)
            context.setLineWidth(currentWidth)
            context.setLineCap(.round)
            context.setLineJoin(.round)
            context.addPath(currentPath.cgPath)
            context.strokePath()
        }
        
        print("SimpleDrawingView: draw() completed")
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let point = touch.location(in: self)
        currentPath = UIBezierPath()
        currentPath?.move(to: point)
        currentStroke = [point]
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let path = currentPath else { return }
        let point = touch.location(in: self)
        path.addLine(to: point)
        currentStroke.append(point)
        
        // Optimize redraw to only the affected area
        let dirtyRect = CGRect(x: point.x - currentWidth/2 - 2, 
                              y: point.y - currentWidth/2 - 2, 
                              width: currentWidth + 4, 
                              height: currentWidth + 4)
        setNeedsDisplay(dirtyRect)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let path = currentPath else { return }
        paths.append((path: path, color: currentColor, width: currentWidth))
        rawStrokes.append((points: currentStroke, color: currentColor, width: currentWidth))
        currentPath = nil
        currentStroke = []
        
        // Ensure view is ready for drawing
        
        setNeedsDisplay()
    }
    
    func setColor(_ color: UIColor) {
        currentColor = color
    }
    
    func setWidth(_ width: CGFloat) {
        currentWidth = width
    }
    
    func undo() {
        if !paths.isEmpty && !rawStrokes.isEmpty {
            paths.removeLast()
            rawStrokes.removeLast()
            print("SimpleDrawingView: Undo - \(paths.count) paths remaining, \(rawStrokes.count) raw strokes remaining")
            
            // Force complete visual reset and redraw
            forceCompleteRedraw()
        }
    }
    
    func clear() {
        print("SimpleDrawingView: Clear called - before: \(paths.count) paths, \(rawStrokes.count) strokes")
        
        // Completely reset all state
        paths.removeAll(keepingCapacity: false)
        rawStrokes.removeAll(keepingCapacity: false)
        currentPath = nil
        currentStroke.removeAll(keepingCapacity: false)
        
        print("SimpleDrawingView: Clear - after removeAll: \(paths.count) paths, \(rawStrokes.count) strokes")
        
        // Force complete visual reset with aggressive clearing
        forceCompleteRedraw()
        
        print("SimpleDrawingView: Clear completed - all state reset")
    }
    
    func getAllAnnotations() -> [(path: UIBezierPath, color: UIColor, width: CGFloat)] {
        return paths
    }
    
    private func forceCompleteRedraw() {
        // Aggressively clear all visual state
        layer.contents = nil
        layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        
        // Clear the entire view by filling with clear color
        if let context = UIGraphicsGetCurrentContext() {
            context.clear(bounds)
            context.setFillColor(UIColor.clear.cgColor)
            context.fill(bounds)
        }
        
        // Force the view to completely redraw by invalidating its display
        setNeedsDisplay(bounds)
        
        // Create a temporary clear overlay to ensure visual clearing
        let clearOverlay = UIView(frame: bounds)
        clearOverlay.backgroundColor = UIColor.clear
        addSubview(clearOverlay)
        
        // Remove the overlay after a brief moment
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            clearOverlay.removeFromSuperview()
            guard let self = self else { return }
            print("SimpleDrawingView: Force redraw verification - \(self.paths.count) paths, \(self.rawStrokes.count) strokes")
            self.setNeedsDisplay(self.bounds)
        }
    }
}

// MARK: - UITextView Delegate

extension FeedbackViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == .placeholderText {
            textView.text = ""
            textView.textColor = .label
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Describe the issue you encountered..."
            textView.textColor = .placeholderText
        } else {
            feedbackText = textView.text
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        if textView.textColor != .placeholderText {
            feedbackText = textView.text
        }
    }
}
