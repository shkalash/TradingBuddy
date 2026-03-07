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
