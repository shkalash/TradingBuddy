import SwiftUI

/// A sidebar section that displays a categorized list of tags within a disclosure group.
///
/// **Responsibilities:**
/// - Rendering a collection of `Tag` objects as navigation links.
/// - Managing the expansion state of its category group.
/// - Applying category-specific icons and colors.
struct TagSidebarSection: View {
    // MARK: - Properties
    
    let title: String
    let tags: [Tag]
    let icon: String
    let color: Color
    
    @State private var isExpanded = true
    
    // MARK: - Body
    
    var body: some View {
        if !tags.isEmpty {
            DisclosureGroup(isExpanded: $isExpanded) {
                ForEach(tags, id: \.id) { tag in
                    NavigationLink(value: NavigationSelection.tag(tag.id)) {
                        Label(tag.id, systemImage: icon)
                            .foregroundStyle(color)
                    }
                }
            } label: {
                ClickableDisclosureLabel(title: title, isExpanded: $isExpanded, isSubheadline: true)
            }
        }
    }
}
