import SwiftUI
struct ContentView: View {
    @Environment(ChatViewModel.self) private var viewModel
    @Environment(AppRouter.self) private var router
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    let repository: JournalRepository
    let imageStorage: ImageStorageService
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
        .onChange(of: router.selection) { _, newSelection in
            guard let newSelection = newSelection else { return }
            Task {
                switch newSelection {
                case .day(let date):
                    await viewModel.load(day: date)
                case .tag(let tagId):
                    await viewModel.load(tag: tagId)
                }
            }
        }// Listen for the clear signal from the Settings window
        .onReceive(NotificationCenter.default.publisher(for: .databaseCleared)) { _ in
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
        // MARK: - DEBUG TOOLBAR
                .toolbar {
                    #if DEBUG
                    ToolbarItemGroup(placement: .navigation) {
                        // POPULATE BUTTON
                        Button(action: {
                            Task {
                                if let repo = repository as? GRDBJournalRepository {
                                    try? await repo.debugPopulate()
                                    // Broadcast the update so Sidebar and Chat instantly refresh
                                    NotificationCenter.default.post(name: .databaseCleared, object: nil)
                                }
                            }
                        }) {
                            Label("Seed DB", systemImage: "sparkles")
                                .foregroundColor(.purple)
                        }
                        .help("Populate DB with random data")
                        
                        // NUKE BUTTON
                        Button(action: {
                            Task {
                                try? await repository.clearDatabase()
                                try? imageStorage.clearAllImages()
                                NotificationCenter.default.post(name: .databaseCleared, object: nil)
                            }
                        }) {
                            Label("Nuke DB", systemImage: "flame.fill")
                                .foregroundColor(.red)
                        }
                        .help("Instantly wipe DB and images without asking")
                    }
                    #endif
                }
    }
}
