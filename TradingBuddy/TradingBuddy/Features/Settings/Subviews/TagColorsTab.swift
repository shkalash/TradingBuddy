import SwiftUI

/// A settings tab for customizing the colors associated with different tag categories.
///
/// **Responsibilities:**
/// - Organizing tag categories into an easy-to-read list.
/// - Providing access to color pickers for each `TagType`.
struct TagColorsTab: View {
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("settings.tags.header")
                .font(.headline)
            
            VStack(spacing: 16) {
                CategoryColorRow(title: String(localized: "settings.tags.category.future", comment: "Future category label"), type: .future)
                CategoryColorRow(title: String(localized: "settings.tags.category.topic", comment: "Topic category label"), type: .topic)
                CategoryColorRow(title: String(localized: "settings.tags.category.ticker", comment: "Ticker category label"), type: .ticker)
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2)))
            
            Spacer()
        }
        .padding(20)
    }
}
