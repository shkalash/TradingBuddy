import SwiftUI
import GRDB

@main
struct TradingBuddyApp: App {
    let repository: JournalRepository
    let imageStorage: ImageStorageService
    
    @State private var viewModel: ChatViewModel
    @State private var router: AppRouter
    @State private var colorService = TagColorService()
    
    init() {
        // 1. Initialize the Image Storage FIRST
        let storage = LocalImageStorageService()
        self.imageStorage = storage
        
        // 2. Initialize the Database Setup
        // (Ensuring the TradingBuddy folder exists in Application Support)
        let appSupportURL = try! FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let appDirectory = appSupportURL.appendingPathComponent("TradingBuddy", isDirectory: true)
        try? FileManager.default.createDirectory(at: appDirectory, withIntermediateDirectories: true)
        
        let dbURL = appDirectory.appendingPathComponent("journal.sqlite")
        let dbQueue = try! DatabaseQueue(path: dbURL.path)
        let appDb = try! AppDatabase(dbQueue)
        
        let timeProvider = SystemTimeProvider()
        let dayCalculator = ChicagoTradingDayService()
        let parser = RegexMessageParser()
        
        let repo = GRDBJournalRepository(
            appDb: appDb,
            timeProvider: timeProvider,
            dayCalculator: dayCalculator,
            parser: parser
        )
        self.repository = repo
        
        // 3. Initialize the ViewModel
        let prefs = AppPreferencesService()
        let initialRouter = AppRouter()
        
        let vm = ChatViewModel(
            repository: repo,
            timeProvider: timeProvider,
            dayCalculator: dayCalculator,
            preferences: prefs,
            router: initialRouter,
            imageStorage: storage
        )
        
        self._viewModel = State(wrappedValue: vm)
        self._router = State(wrappedValue: initialRouter)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(repository: repository, imageStorage: imageStorage)
                .environment(viewModel)
                .environment(router)
                .environment(colorService)
        }
        
        Settings {
            SettingsView(repository: repository, imageStorage: imageStorage)
                .environment(colorService)
        }
    }
}
