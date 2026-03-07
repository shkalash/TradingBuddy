import SwiftUI
import AppKit

struct CategoryColorPopover: View {
    let type: TagType
    @State var draftColor: Color
    @Binding var isPresented: Bool
    
    @Environment(TagColorService.self) private var colorService
    @State private var actionTaken = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Select Color").font(.headline)
            
            ColorPicker("Color", selection: $draftColor)
                .labelsHidden()
            
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
        .padding(16)
        .frame(width: 220)
        .onDisappear {
            // If they click off the popover (without hitting a button), save it automatically!
            if !actionTaken {
                colorService.setColor(draftColor, for: type)
            }
            
            // If the popover vanishes, ensure the floating Mac color grid vanishes with it
            NSColorPanel.shared.close()
        }
    }
    
    private func closeAllWindows() {
        // 1. Tell SwiftUI to update the state
        isPresented = false
        
        // 2. The Nuclear Option: Send a raw AppKit command up the responder chain to force the Popover closed
        NSApp.sendAction(#selector(NSPopover.performClose(_:)), to: nil, from: nil)
        
        // 3. Force the floating macOS System Color Panel to close
        NSColorPanel.shared.close()
    }
}
