import SwiftUI
import AppKit

extension Notification.Name {
    static let databaseUpdated = Notification.Name("databaseUpdated")
    static let databaseCleared = Notification.Name("TradingBuddy.databaseCleared")
}

struct SettingsView: View {
    let repository: JournalRepository
    let imageStorage: ImageStorageService
    @Environment(TagColorService.self) private var colorService
    
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
