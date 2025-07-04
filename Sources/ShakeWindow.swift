//
//  ShakeWindow.swift
//  ShakeFeedbackKit
//
//  Created by Ali Abdulkadir Ali on 29/06/2025.
//


import UIKit
import Combine

/// UIWindow subclass that emits a Combine event whenever the user shakes the device.
final class ShakeWindow: UIWindow {
  private let subject = PassthroughSubject<Void, Never>()
  /// Public publisher you’ll subscribe to later.
  var shakePublisher: AnyPublisher<Void, Never> { subject.eraseToAnyPublisher() }

  // iOS 13+: UIEvent.EventSubtype (note the enum namespace change!)
  override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
    guard motion == .motionShake else { return }
    subject.send()
  }
}

// Convenience to fetch the first ShakeWindow per scene (handles multi-window on iPad).
extension Sequence where Element == UIScene {
  var firstShakeWindow: ShakeWindow? {
    compactMap { ($0 as? UIWindowScene)?
      .windows
      .first(where: { $0 is ShakeWindow }) as? ShakeWindow
    }.first
  }
}