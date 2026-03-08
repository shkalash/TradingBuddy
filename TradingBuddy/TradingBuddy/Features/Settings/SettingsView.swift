import SwiftUI
import AppKit

/// The unified interface for managing application preferences and customizations.
///
/// **Responsibilities:**
/// - Providing tabs for general settings and tag color management.
/// - Displaying destructive actions for database management.
/// - Persisting user preferences across app launches.
struct SettingsView: View {
    // MARK: - Properties
    
    let dependencies: any AppDependencies
    
    // MARK: - Body
    
    var body: some View {
        TabView {
            GeneralSettingsTab(dependencies: dependencies)
                .tabItem { 
                    Label(String(localized: "settings.tab.general", comment: "General settings tab title"), systemImage: "gearshape") 
                }
            
            TagColorsTab(dependencies: dependencies)
                .tabItem { 
                    Label(String(localized: "settings.tab.tags", comment: "Tag colors settings tab title"), systemImage: "paintpalette") 
                }
            
            ClipboardSettingsTab(dependencies: dependencies)
                .tabItem {
                    Label(String(localized: "settings.tab.clipboard", defaultValue: "Clipboard"), systemImage: "paperclip")
                }
        }
        .frame(width: 450, height: 350)
    }
}

// MARK: - Previews

#Preview {
    let mockDeps = PreviewMocks.MockDependencyContainer()
    return SettingsView(dependencies: mockDeps)
}
