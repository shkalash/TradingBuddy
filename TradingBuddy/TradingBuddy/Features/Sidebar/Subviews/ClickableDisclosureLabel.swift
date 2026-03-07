import SwiftUI

/// A reusable label component that toggles a disclosure group's expansion when tapped.
///
/// **Responsibilities:**
/// - Providing a full-width clickable area for disclosure labels.
/// - Handling toggle animations for expansion state.
/// - Supporting standard and subheadline font weights.
struct ClickableDisclosureLabel: View {
    // MARK: - Properties
    
    let title: String
    @Binding var isExpanded: Bool
    var isSubheadline: Bool = false
    
    // MARK: - Body
    
    var body: some View {
        Text(title)
            .font(isSubheadline ? .subheadline.weight(.semibold) : .system(.body, weight: .medium))
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation {
                    isExpanded.toggle()
                }
            }
    }
}
