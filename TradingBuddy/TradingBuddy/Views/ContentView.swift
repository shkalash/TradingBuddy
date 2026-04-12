import SwiftUI
import AppKit

/// The root navigation container for the TradingBuddy application.
///
/// **Responsibilities:**
/// - Orchestrating the primary `NavigationSplitView`.
/// - Managing the global toolbar and debug utilities.
/// - Responding to system-wide database reset events.
struct ContentView: View {
    // MARK: - Properties
    
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    
    let dependencies: any AppDependencies
    
    // MARK: - Body
    
    var body: some View {
        Group {
            switch dependencies.router.viewMode {
            case .chat:
                NavigationSplitView(columnVisibility: $columnVisibility) {
                    SidebarView(dependencies: dependencies)
                } detail: {
                    ChatView(dependencies: dependencies)
                        .toolbar {
                            ToolbarItem(placement: .navigation) {
                                Button(action: {
                                    dependencies.router.viewMode = .rules
                                }) {
                                    Label(String(localized: "chat.toolbar.show_rules", defaultValue: "Show Rules"), systemImage: "doc.text")
                                }
                                .help(String(localized: "chat.toolbar.show_rules.help", defaultValue: "Show Rules"))
                                .accessibilityIdentifier("showRulesButton")
                            }
                        }
                }
            case .rules:
                NavigationStack {
                    RulesView(dependencies: dependencies)
                }
            }
        }
        .task {
            // Initial load
            dependencies.router.selection = .day(dependencies.session.activeTradingDay)
        }
#if DEBUG
        .toolbar {
            debugToolbar
        }
#endif
    }
    
    // MARK: - Subviews
#if DEBUG
    @ToolbarContentBuilder
    private var debugToolbar: some ToolbarContent {

        ToolbarItemGroup(placement: .navigation) {
            Button(action: {
                Task {
                    if let repo = dependencies.repository as? GRDBJournalRepository {
                        try? await repo.debugPopulate()
                        NotificationCenter.default.post(name: AppConstants.Notifications.databaseUpdated, object: nil)
                    }
                }
            }) {
                Label("Seed DB", systemImage: "sparkles")
                    .foregroundStyle(.purple)
            }
            .help("Populate DB with random data")
            
            Button(action: {
                Task {
                    await dependencies.commands.resetDatabase(includingImages: true)
                }
            }) {
                Label("Nuke DB", systemImage: "flame.fill")
                    .foregroundStyle(.red)
            }
            .help("Instantly wipe DB and images without asking")
        }

    }
#endif
}

// MARK: - Previews

#Preview {
    let mockDeps = PreviewMocks.MockDependencyContainer()
    return ContentView(dependencies: mockDeps)
}
