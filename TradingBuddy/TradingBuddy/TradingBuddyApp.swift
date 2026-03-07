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
    
    private let repository: JournalRepository
    private let imageStorage: ImageStorageService
    
    @State private var viewModel: ChatViewModel
    @State private var router: AppRouter
    @State private var colorService = TagColorService()
    
    // MARK: - Initialization
    
    init() {
        let storage = LocalImageStorageService()
        self.imageStorage = storage
        
        let appDb = try! AppDatabase.shared()
        
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
    
    // MARK: - Body
    
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
