import SwiftUI

struct CategoryColorRow: View {
    let title: String
    let type: TagType
    
    @Environment(TagColorService.self) private var colorService
    @State private var isShowingPopover = false
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(.body, design: .monospaced))
            
            Spacer()
            
            Circle()
                .fill(colorService.getColor(for: type))
                .frame(width: 24, height: 24)
                .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 1))
                .onTapGesture {
                    isShowingPopover = true
                }
                .popover(isPresented: $isShowingPopover, arrowEdge: .trailing) {
                    // Pass the binding directly so the child can force it to close
                    CategoryColorPopover(
                        type: type,
                        draftColor: colorService.getColor(for: type),
                        isPresented: $isShowingPopover
                    )
                }
        }
    }
}
