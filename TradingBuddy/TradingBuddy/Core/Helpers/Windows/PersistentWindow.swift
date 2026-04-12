import Foundation
import SwiftUI
import Combine

/// A Codable struct to store the window's frame information.
struct WindowState: Codable {
    let frame: CGRect
    let isFullScreen: Bool
}

/// The ViewModifier that applies the persistent frame logic.
struct PersistentWindow: ViewModifier {
    private let key: String
    private let onLoad: (String) -> WindowState?
    private let onSave: (String, WindowState) -> Void
    
    // We store the notification observers in a property to keep them alive.
    @State private var observers: [AnyObject] = []
    @State private var savedFrame: CGRect = .zero
    init(key: String, onLoad: @escaping (String) -> WindowState?, onSave: @escaping (String, WindowState) -> Void) {
        self.key = key
        self.onLoad = onLoad
        self.onSave = onSave
    }

    func body(content: Content) -> some View {
        content
            .background(
                WindowAccessor { window in
                    // Only apply if we haven't already.
                    // This avoids recursion or repeated triggers.
                    if observers.isEmpty {
                        applySavedState(to: window)
                        setupObservers(for: window)
                    }
                }
            )
    }
    
    private func applySavedState(to window: NSWindow) {
        if let state = onLoad(key) {
            // First set the frame
            window.setFrame(state.frame, display: true)
            savedFrame = state.frame
            // Then if it was full screen, toggle it.
            // We use a small delay or async to ensure the window is ready for the transition.
            if state.isFullScreen {
                DispatchQueue.main.async {
                    if !window.styleMask.contains(.fullScreen) {
                        window.toggleFullScreen(nil)
                    }
                }
            }
        } else {
            // Provide a sensible default if no state is saved.
            window.setContentSize(NSSize(width: 900, height: 600))
            window.center()
            savedFrame = window.frame
        }
    }
    
    private func setupObservers(for window: NSWindow) {
        // Prevent adding observers multiple times.
        guard observers.isEmpty else { return }
        
        let center = NotificationCenter.default
        
        // Save state on move
        let moveObserver = center.addObserver(
            forName: NSWindow.didMoveNotification,
            object: window,
            queue: .main
        ) { _ in
            save(window: window)
        }
        
        // Save state on resize
        let resizeObserver = center.addObserver(
            forName: NSWindow.didEndLiveResizeNotification,
            object: window,
            queue: .main
        ) { _ in
            save(window: window)
        }
        
        // Save state on entering/exiting full screen
        let enterFullScreenObserver = center.addObserver(
            forName: NSWindow.didEnterFullScreenNotification,
            object: window,
            queue: .main
        ) { _ in
            save(window: window)
        }
        
        let exitFullScreenObserver = center.addObserver(
            forName: NSWindow.didExitFullScreenNotification,
            object: window,
            queue: .main
        ) { _ in
            save(window: window)
        }
        
        self.observers = [moveObserver, resizeObserver, enterFullScreenObserver, exitFullScreenObserver]
    }
    
    private func save(window: NSWindow) {
        let isFullScreen = window.styleMask.contains(.fullScreen)
        if !isFullScreen { savedFrame = window.frame }
        onSave(key, WindowState(frame: savedFrame, isFullScreen: isFullScreen))
    }
}


