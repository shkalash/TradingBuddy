import SwiftUI

struct TagSidebarSection: View {
    let title: String
    let tags: [Tag]
    let icon: String
    let color: Color
    @State private var isExpanded = true
    
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
