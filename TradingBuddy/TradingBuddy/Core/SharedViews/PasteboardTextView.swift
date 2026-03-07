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
        let scrollView = NSTextView.scrollableTextViewWithPaste()
        let textView = scrollView.documentView as! PasteboardEnabledTextView
        
        textView.delegate = context.coordinator
        textView.onImagePasted = onImagePasted
        
        textView.isRichText = false
        textView.allowsUndo = true
        textView.isEditable = true
        textView.isSelectable = true
        textView.font = .systemFont(ofSize: 14)
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        
        // Ensure the text view can become first responder
        textView.isFieldEditor = false
        
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        let textView = nsView.documentView as! PasteboardEnabledTextView
        textView.onImagePasted = onImagePasted
        
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
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                if let event = NSApp.currentEvent, event.modifierFlags.contains(.shift) {
                    return false
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
        
        // 1. Check for NSImage objects
        if let images = pb.readObjects(forClasses: [NSImage.self], options: nil) as? [NSImage], let first = images.first {
            onImagePasted?(first)
            return
        }
        
        // 2. Fallback to direct data types (TIFF or PNG)
        let imageTypes: [NSPasteboard.PasteboardType] = [.tiff, .png]
        for type in imageTypes {
            if let data = pb.data(forType: type), let image = NSImage(data: data) {
                onImagePasted?(image)
                return
            }
        }
        
        // 3. Fallback to standard text paste
        super.paste(sender)
    }
    
    override func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        if item.action == #selector(paste(_:)) {
            return true
        }
        return super.validateUserInterfaceItem(item)
    }
}

extension NSTextView {
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
        
        if let textContainer = textView.textContainer {
            textContainer.containerSize = NSSize(width: contentSize.width, height: CGFloat.greatestFiniteMagnitude)
            textContainer.widthTracksTextView = true
        }
        
        scrollView.documentView = textView
        return scrollView
    }
}
