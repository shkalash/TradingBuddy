import SwiftUI

/// A single row in the Tag Colors tab representing a specific category.
///
/// **Responsibilities:**
/// - Rendering the category title and its current color indicator.
/// - Managing the presentation of the `CategoryColorPopover`.
struct CategoryColorRow: View {
    // MARK: - Properties
    
    let title: String
    let type: TagType
    let dependencies: any AppDependencies
    
    @State private var isShowingPopover = false
    
    // MARK: - Body
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(.body, design: .monospaced))
            
            Spacer()
            
            colorIndicator
        }
    }
    
    // MARK: - Components
    
    private var colorIndicator: some View {
        Circle()
            .fill(dependencies.colorService.getColor(for: type))
            .frame(width: 24, height: 24)
            .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 1))
            .onTapGesture { isShowingPopover = true }
            .popover(isPresented: $isShowingPopover, arrowEdge: .trailing) {
                CategoryColorPopover(
                    type: type,
                    draftColor: dependencies.colorService.getColor(for: type),
                    isPresented: $isShowingPopover,
                    dependencies: dependencies
                )
            }
    }
}
