# Changelog

All notable changes to ShakeFeedbackKit will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.1.0] - 2025-08-03

### Added
- **Robust annotation system with persistent state:**
  - Custom lightweight annotation UI with pen and highlighter tools
  - Color picker with 6 predefined colors (Red, Blue, Green, Orange, Purple, Black)
  - Cross-session annotation persistence using serializable AnnotationData
  - Comprehensive undo functionality for all annotations (current + previous sessions)
  - Clear all annotations with confirmation dialog
  - Visual feedback improvements with immediate clearing or auto-navigation
  - Dual-tracking system (UIBezierPath + raw points) for reliable state management

### Changed
- **Enhanced FeedbackComposer UI:**
  - Replaced complex PencilKit implementation with streamlined custom solution
  - Improved annotation toolbar with visually distinct icons (crayon for highlighter)
  - Better aspect-fit scaling for annotations on screenshots
  - Optimized drawing performance with efficient redraw logic

### Fixed
- **Annotation persistence and visual feedback:**
  - Fixed annotation clearing not showing immediate visual feedback
  - Resolved state synchronization issues between stored and displayed annotations
  - Fixed undo functionality to work across annotation sessions
  - Eliminated layout constraint warnings and CoreGraphics errors
  - Improved annotation serialization to preserve all stroke data

## [1.0.0] - 2025-07-05

### Added
- Initial public release
- Shake gesture detection for UIKit and SwiftUI apps
- Automatic screenshot capture
- Feedback form with note input
- Jira integration with issue creation
- Device metadata collection and reporting
- MIT License
