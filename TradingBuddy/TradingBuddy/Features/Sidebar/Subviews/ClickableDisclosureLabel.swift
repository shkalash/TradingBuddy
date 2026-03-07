import SwiftUI

struct ClickableDisclosureLabel: View {
    let title: String
    @Binding var isExpanded: Bool
    var isSubheadline: Bool = false
    
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
