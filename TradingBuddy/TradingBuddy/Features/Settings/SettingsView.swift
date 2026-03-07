import SwiftUI
import AppKit

extension Notification.Name {
    static let databaseUpdated = Notification.Name("databaseUpdated")
    static let databaseCleared = Notification.Name("TradingBuddy.databaseCleared")
}

/// The unified interface for managing application preferences and customizations.
///
/// **Responsibilities:**
/// - Providing tabs for general settings and tag color management.
/// - Displaying destructive actions for database management.
/// - Persisting user preferences across app launches.
struct SettingsView: View {
    // MARK: - Properties
    
    let repository: JournalRepository
    let imageStorage: ImageStorageService
    @Environment(TagColorService.self) private var colorService
    
    // MARK: - Body
    
    var body: some View {
        TabView {
            GeneralSettingsTab(repository: repository, imageStorage: imageStorage)
                .tabItem { Label("General", systemImage: "gearshape") }
            
            TagColorsTab()
                .tabItem { Label("Tags", systemImage: "paintpalette") }
        }
        .frame(width: 450, height: 350)
    }
}

// MARK: - Previews

#Preview {
    SettingsView(
        repository: PreviewMocks.MockRepo(),
        imageStorage: PreviewMocks.MockImageStorage()
    )
    .environment(TagColorService())
}
