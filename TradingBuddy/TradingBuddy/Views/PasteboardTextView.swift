import SwiftUI
import AppKit

struct PasteboardTextView: NSViewRepresentable {
    @Binding var text: String
    var onImagePasted: ((NSImage) -> Void)?
    var onSubmit: (() -> Void)?
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeNSView(context: Context) -> NSScrollView {
        // 1. Create the ScrollView manually
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        
        // 2. Create our Custom Subclass
        let textView = CustomNSTextView()
        
        // 3. Configure it to auto-wrap text correctly
        textView.autoresizingMask = [.width]
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainer?.widthTracksTextView = true
        
        // 4. Style it
        textView.drawsBackground = false
        textView.isRichText = false
        textView.allowsUndo = true
        textView.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        
        // 5. Hook up delegates and closures
        textView.delegate = context.coordinator
        textView.onImagePasted = onImagePasted
        textView.onSubmit = onSubmit
        
        scrollView.documentView = textView
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        context.coordinator.parent = self
        guard let textView = nsView.documentView as? CustomNSTextView else { return }
        
        // Ensure closures stay fresh
        textView.onImagePasted = onImagePasted
        textView.onSubmit = onSubmit
        
        if textView.string != text {
            let selectedRanges = textView.selectedRanges
            textView.string = text
            textView.selectedRanges = selectedRanges
        }
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: PasteboardTextView
        
        init(_ parent: PasteboardTextView) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            self.parent.text = textView.string
        }
    }
}

// MARK: - AppKit Subclass

class CustomNSTextView: NSTextView {
    var onImagePasted: ((NSImage) -> Void)?
    var onSubmit: (() -> Void)?
    
    // 1. FORCE MACOS TO ENABLE THE PASTE BUTTON
    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if menuItem.action == #selector(paste(_:)) {
            // If there's an image on the clipboard, tell macOS we are allowed to paste it!
            if NSPasteboard.general.canReadObject(forClasses: [NSImage.self], options: nil) {
                return true
            }
        }
        return super.validateMenuItem(menuItem)
    }
    
    // 2. INTERCEPT THE PASTE ACTION (Cmd+V or Right Click -> Paste)
    override func paste(_ sender: Any?) {
        if let image = NSImage(pasteboard: NSPasteboard.general) {
            onImagePasted?(image)
            return // Stop here so the image data isn't shoved into the text field
        }
        super.paste(sender) // Fallback for normal text
    }
    
    // 3. INTERCEPT THE ENTER KEY
    override func insertNewline(_ sender: Any?) {
        if let event = NSApplication.shared.currentEvent, event.modifierFlags.contains(.shift) {
            super.insertNewline(sender) // Shift+Enter = normal new line
        } else {
            onSubmit?() // Enter = Send message
        }
    }
}
