import SwiftUI
import AppKit

/// A popover interface for selecting and applying a new color to a tag category.
///
/// **Responsibilities:**
/// - Providing a `ColorPicker` for user selection.
/// - Handling "Apply" and "Cancel" logic with keyboard shortcuts.
/// - Ensuring proper dismissal of system-level color panels.
struct CategoryColorPopover: View {
    // MARK: - Properties
    
    let type: TagType
    @State var draftColor: Color
    @Binding var isPresented: Bool
    
    @Environment(TagColorService.self) private var colorService
    @State private var actionTaken = false
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            
            ColorPicker("Color", selection: $draftColor)
                .labelsHidden()
            
            footer
        }
        .padding(16)
        .frame(width: 220)
        .onDisappear { handleDisappear() }
    }
    
    // MARK: - Components
    
    private var header: some View {
        Text("Select Color").font(.headline)
    }
    
    private var footer: some View {
        HStack {
            Button("Cancel") {
                actionTaken = true
                closeAllWindows()
            }
            .keyboardShortcut(.cancelAction)
            
            Spacer()
            
            Button("Apply") {
                actionTaken = true
                colorService.setColor(draftColor, for: type)
                closeAllWindows()
            }
            .keyboardShortcut(.defaultAction)
            .buttonStyle(.borderedProminent)
        }
    }
    
    // MARK: - Logic
    
    private func handleDisappear() {
        // If they click off the popover (without hitting a button), save it automatically!
        if !actionTaken {
            colorService.setColor(draftColor, for: type)
        }
        // If the popover vanishes, ensure the floating Mac color grid vanishes with it
        NSColorPanel.shared.close()
    }
    
    private func closeAllWindows() {
        isPresented = false
        // The Nuclear Option: Send a raw AppKit command up the responder chain to force the Popover closed
        NSApp.sendAction(#selector(NSPopover.performClose(_:)), to: nil, from: nil)
        NSColorPanel.shared.close()
    }
}
