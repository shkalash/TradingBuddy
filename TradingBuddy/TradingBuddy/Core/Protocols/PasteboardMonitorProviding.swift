import Foundation
import AppKit
import Combine

/// A service that monitors the system pasteboard for new image content.
///
/// **Responsibilities:**
/// - Polling the system pasteboard for changes.
/// - Emitting new images when they are detected.
public protocol PasteboardMonitorProviding: AnyObject {
    /// A publisher that emits a new image whenever one is detected on the pasteboard.
    var imagePublisher: AnyPublisher<NSImage, Never> { get }
    
    /// Starts the monitoring loop.
    func startMonitoring()
    
    /// Stops the monitoring loop.
    func stopMonitoring()
}
