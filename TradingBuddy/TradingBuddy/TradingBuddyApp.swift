import SwiftUI
import GRDB

@main
struct TradingBuddyApp: App {
    @State private var viewModel: ChatViewModel
    private let repository: JournalRepository
    private let imageStorage = LocalImageStorageService()
    private let router = AppRouter()
    init() {
        // Setup Database Path
        let appSupportURL = try! FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let appDirectory = appSupportURL.appendingPathComponent("TradingBuddy", isDirectory: true)
        try? FileManager.default.createDirectory(at: appDirectory, withIntermediateDirectories: true)
        
        let dbURL = appDirectory.appendingPathComponent("journal.sqlite")
        
        // Initialize GRDB Pool and Schema
        let dbPool = try! DatabasePool(path: dbURL.path)
        let appDb = try! AppDatabase(dbPool)
        
        // Initialize Services
        let timeProvider = SystemTimeProvider()
        let dayCalculator = ChicagoTradingDayService()
        let parser = RegexMessageParser()
        let preferences = AppPreferencesService()
        
        self.repository = GRDBJournalRepository(
            appDb: appDb,
            timeProvider: timeProvider,
            dayCalculator: dayCalculator,
            parser: parser
        )
        
        // Inject into ViewModel
        let vm = ChatViewModel(
            repository: self.repository,
            timeProvider: timeProvider,
            dayCalculator: dayCalculator,
            preferences: preferences,
            router: router,
            imageStorage: imageStorage
        )
        
        _viewModel = State(initialValue: vm)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(repository: repository,imageStorage: imageStorage)
                .environment(viewModel)
                .environment(router)
        }
        
        Settings {
            SettingsView(repository: repository, imageStorage: imageStorage)
        }
    }
}
