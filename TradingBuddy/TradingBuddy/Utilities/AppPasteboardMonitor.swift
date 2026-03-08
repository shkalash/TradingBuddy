import Foundation
import AppKit
import Combine

/// The production implementation of `PasteboardMonitorProviding`.
///
/// **Responsibilities:**
/// - Using a low-priority timer to watch `NSPasteboard.general.changeCount`.
/// - Identifying and extracting PNG/TIFF data from the pasteboard.
/// - Throttling detection to avoid duplicate triggers.
public final class AppPasteboardMonitor: PasteboardMonitorProviding {
    // MARK: - Properties
    
    private let pasteboard = NSPasteboard.general
    private var lastChangeCount = NSPasteboard.general.changeCount
    private var timer: AnyCancellable?
    
    private let imageSubject = PassthroughSubject<NSImage, Never>()
    public var imagePublisher: AnyPublisher<NSImage, Never> {
        imageSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    
    public init() {}
    
    // MARK: - API
    
    public func startMonitoring() {
        guard timer == nil else { return }
        
        // Record current state to avoid triggering on old clipboard content on launch
        lastChangeCount = pasteboard.changeCount
        
        timer = Timer.publish(every: 0.5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.checkPasteboard()
            }
    }
    
    public func stopMonitoring() {
        timer?.cancel()
        timer = nil
    }
    
    // MARK: - Private
    
    private func checkPasteboard() {
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount
        
        // Look for image types (screenshots are typically TIFF or PNG)
        let supportedTypes: [NSPasteboard.PasteboardType] = [.tiff, .png]
        
        if let bestType = pasteboard.availableType(from: supportedTypes),
           let data = pasteboard.data(forType: bestType),
           let image = NSImage(data: data) {
            
            // Only emit if the app is NOT already frontmost.
            // If it is frontmost, we assume the user is doing a manual paste (Cmd+V)
            // or we've already handled the intake.
            if !NSApp.isActive {
                imageSubject.send(image)
            }
        }
    }
}
