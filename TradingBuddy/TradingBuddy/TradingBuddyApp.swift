import SwiftUI
import GRDB

/// The entry point of the TradingBuddy application.
///
/// **Responsibilities:**
/// - Initializing core services and infrastructure (Database, Image Storage).
/// - Injecting global state (ViewModel, Router, Color Service) into the environment.
/// - Defining the primary window group and settings scene.
@main
struct TradingBuddyApp: App {
    // MARK: - Properties
    private let windowName = "io.shkalash.TradingBuddy"
    private let dependencies: DependencyContainer
    
    // MARK: - Initialization
    
    init() {
        self.dependencies = DependencyContainer()
    }
    
    // MARK: - Body
    
    var body: some Scene {
        WindowGroup {
            ContentView(dependencies: dependencies)
                .persistentFrame(
                    forKey: windowName,
                    onLoad: { key in
                        dependencies.persistenceHandler.loadCodable(for: .windowState(name: key))?.frame
                    },
                    onSave: { key, frame in
                        dependencies.persistenceHandler.saveCodable(object: WindowState(frame: frame), for: .windowState(name: key))
                    }
                )
        }
        .commands {
            // Append to the system View menu instead of creating a new one
            CommandGroup(after: .toolbar) {
                Section {
                    Button(String(localized: "menu.view.increase_font", defaultValue: "Increase Chat Font Size")) {
                        dependencies.preferencesService.chatFontSize += 1
                    }
                    .keyboardShortcut("]", modifiers: .command)
                    
                    Button(String(localized: "menu.view.decrease_font", defaultValue: "Decrease Chat Font Size")) {
                        dependencies.preferencesService.chatFontSize = max(8, dependencies.preferencesService.chatFontSize - 1)
                    }
                    .keyboardShortcut("[", modifiers: .command)
                }
            }
        }
        
        Settings {
            SettingsView(dependencies: dependencies)
        }
    }
}
