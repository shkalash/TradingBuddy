import SwiftUI

/// The root navigation container for the TradingBuddy application.
///
/// **Responsibilities:**
/// - Orchestrating the primary `NavigationSplitView`.
/// - Managing the global toolbar and debug utilities.
/// - Responding to system-wide database reset events.
struct ContentView: View {
    // MARK: - Properties
    
    @Environment(ChatViewModel.self) private var viewModel
    @Environment(AppRouter.self) private var router
    
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    
    let repository: JournalRepository
    let imageStorage: ImageStorageService
    
    // MARK: - Body
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(repository: repository)
        } detail: {
            ChatView()
        }
        .task {
            // Initial load
            router.selection = .day(viewModel.activeTradingDay)
        }
        // Watch the router, load data when it changes
        .task(id: router.selection) {
            guard let selection = router.selection else { return }
            switch selection {
                case .day(let date): await viewModel.load(day: date)
                case .tag(let tagId): await viewModel.load(tag: tagId)
            }
        }
        // Listen for the clear signal from the Settings window
        .onReceive(NotificationCenter.default.publisher(for: AppConstants.Notifications.databaseCleared)) { _ in
            Task {
                // Force a reload of whatever view we are currently looking at
                if let newSelection = router.selection {
                    switch newSelection {
                        case .day(let date): await viewModel.load(day: date)
                        case .tag(let tagId): await viewModel.load(tag: tagId)
                    }
                }
            }
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
                    if let repo = repository as? GRDBJournalRepository {
                        try? await repo.debugPopulate()
                        NotificationCenter.default.post(name: AppConstants.Notifications.databaseCleared, object: nil)
                    }
                }
            }) {
                Label("Seed DB", systemImage: "sparkles")
                    .foregroundStyle(.purple)
            }
            .help("Populate DB with random data")
            
            Button(action: {
                Task {
                    try? await repository.clearDatabaseOnly()
                    try? imageStorage.clearAllImages()
                    NotificationCenter.default.post(name: AppConstants.Notifications.databaseCleared, object: nil)
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
    ContentView(
        repository: PreviewMocks.MockRepo(),
        imageStorage: PreviewMocks.MockImageStorage()
    )
    .environment(PreviewMocks.makeChatViewModel())
    .environment(AppRouter())
    .environment(TagColorService())
}
