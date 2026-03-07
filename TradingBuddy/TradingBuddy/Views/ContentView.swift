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
                        try? await repository.clearDatabaseOnly()
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
// MARK: - Previews

// 1. Standalone mock dependencies for the preview
private class PreviewRepo: JournalRepository {
    func clearDatabaseOnly() async throws {
    }
    
    func clearDatabaseAndImages() async throws {
    }
    
    func saveEntry(text: String, imagePath: String?) async throws -> JournalEntry {
        JournalEntry(id: "1", text: "Preview text", timestamp: Date(), tradingDay: Date())
    }
    func updateEntry(id: String, newText: String) async throws {}
    func entries(for day: Date) async throws -> [JournalEntry] { [] }
    func allTradingDays() async throws -> [Date] { [] }
    func allTags() async throws -> [Tag] { [] }
    func entries(forTag tagId: String) async throws -> [JournalEntry] { [] }
    func clearDatabase() async throws {}
}

private class PreviewImageStorage: ImageStorageService {
    func saveImage(_ image: NSImage, date: Date) async throws -> String { "" }
    func getFileURL(for relativePath: String) -> URL { URL(fileURLWithPath: "") }
    func clearAllImages() throws {}
    func getBaseDirectory() -> URL { URL(fileURLWithPath: "/") }
}

private class PreviewTimeProvider: TimeProvider {
    var now: Date { Date() }
}

private class PreviewPreferences: PreferencesService {
    var showHistoryJumpWarning: Bool = true
    var rolloverPromptDelayHours: Int = 2
    var snoozedUntil: Date? = nil
}

// 2. A wrapper view to safely initialize all our Environment objects
private struct ContentViewPreviewWrapper: View {
    let repo = PreviewRepo()
    let imageStorage = PreviewImageStorage()
    let viewModel: ChatViewModel
    let router = AppRouter()
    let colorService = TagColorService()
    
    init() {
        self.viewModel = ChatViewModel(
            repository: repo,
            timeProvider: PreviewTimeProvider(),
            dayCalculator: ChicagoTradingDayService(),
            preferences: PreviewPreferences(),
            router: router,
            imageStorage: imageStorage
        )
    }
    
    var body: some View {
        ContentView(repository: repo, imageStorage: imageStorage)
            .environment(viewModel)
            .environment(router)
            .environment(colorService)
    }
}

// 3. The clean preview macro
#Preview {
    ContentViewPreviewWrapper()
}
