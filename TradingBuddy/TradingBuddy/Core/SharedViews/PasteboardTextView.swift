import SwiftUI
import AppKit

/// A specialized text input view that supports image pasting from the macOS clipboard.
///
/// **Responsibilities:**
/// - Wrapping a native `NSTextView` for advanced input handling.
/// - Intercepting paste commands to extract `NSImage` data.
/// - Handling "Enter" and "Shift+Enter" for message submission and newlines.
/// - Synchronizing its internal state with a SwiftUI `String` binding.
struct PasteboardTextView: NSViewRepresentable {
    // MARK: - Properties
    
    @Binding var text: String
    var onImagePasted: ((NSImage) -> Void)?
    var onSubmit: (() -> Void)?
    
    // MARK: - NSViewRepresentable
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView
        
        textView.delegate = context.coordinator
        textView.isRichText = false
        textView.allowsUndo = true
        textView.font = .systemFont(ofSize: 14)
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        let textView = nsView.documentView as! NSTextView
        if textView.string != text {
            textView.string = text
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // MARK: - Coordinator
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: PasteboardTextView
        
        init(_ parent: PasteboardTextView) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
        }
        
        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            // Handle Enter key for submission
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                if let event = NSApp.currentEvent, event.modifierFlags.contains(.shift) {
                    return false // Let it insert a newline
                } else {
                    parent.onSubmit?()
                    return true
                }
            }
            return false
        }
    }
}

// MARK: - Custom NSTextView Implementation

/// An internal `NSTextView` subclass that overrides `paste(_:)` to handle image data.
class PasteboardEnabledTextView: NSTextView {
    var onImagePasted: ((NSImage) -> Void)?
    
    override func paste(_ sender: Any?) {
        let pb = NSPasteboard.general
        if let images = pb.readObjects(forClasses: [NSImage.self], options: nil) as? [NSImage], let first = images.first {
            onImagePasted?(first)
        } else {
            super.paste(sender)
        }
    }
}

extension NSTextView {
    /// Helper to initialize the scrollable text view with our custom paste-enabled subclass.
    static func scrollableTextViewWithPaste() -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        
        let contentSize = scrollView.contentSize
        let textView = PasteboardEnabledTextView(frame: NSRect(origin: .zero, size: contentSize))
        textView.minSize = NSSize(width: 0, height: contentSize.height)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = .width
        textView.textContainer?.containerSize = NSSize(width: contentSize.width, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true
        
        scrollView.documentView = textView
        return scrollView
    }
}
