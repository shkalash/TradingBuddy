import Foundation
import SwiftUI
import Combine

/// A Codable struct to store the window's frame information.
struct WindowState: Codable {
    let frame: CGRect
}

/// The ViewModifier that applies the persistent frame logic.
struct PersistentWindowFrame: ViewModifier {
    private let key: String
    private let onLoad: (String) -> CGRect?
    private let onSave: (String, CGRect) -> Void
    
    // We store the notification observers in a property to keep them alive.
    @State private var observers: [AnyObject] = []

    init(key: String, onLoad: @escaping (String) -> CGRect?, onSave: @escaping (String, CGRect) -> Void) {
        self.key = key
        self.onLoad = onLoad
        self.onSave = onSave
    }

    func body(content: Content) -> some View {
        content
            .background(
                WindowAccessor { window in
                    // On first appearance, load and apply the saved frame.
                    applySavedFrame(to: window)
                    // Set up observers to save the frame on change.
                    setupObservers(for: window)
                }
            )
    }
    
    private func applySavedFrame(to window: NSWindow) {
        if let frame = onLoad(key) {
            window.setFrame(frame, display: true)
        } else {
            // Provide a sensible default if no state is saved.
            window.setContentSize(NSSize(width: 900, height: 600))
            window.center()
        }
    }
    
    private func setupObservers(for window: NSWindow) {
        // Prevent adding observers multiple times.
        guard observers.isEmpty else { return }
        
        // Save frame on move
        let moveObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didMoveNotification,
            object: window,
            queue: .main
        ) { _ in
            save(window: window)
        }
        
        // Save frame on resize
        let resizeObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didEndLiveResizeNotification,
            object: window,
            queue: .main
        ) { _ in
            save(window: window)
        }
        
        self.observers = [moveObserver, resizeObserver]
    }
    
    private func save(window: NSWindow) {
        onSave(key, window.frame)
    }
}


