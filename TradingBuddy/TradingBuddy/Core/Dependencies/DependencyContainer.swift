import Foundation
import Combine
import SwiftUI

/// A container for the application's major services and dependencies.
///
/// **Responsibilities:**
/// - Initializing and holding singletons for persistence, repository, and other core services.
/// - Providing a central point for dependency injection.
@MainActor
class DependencyContainer: AppDependencies, ObservableObject {
    // MARK: - Handlers & Services
    
    let persistenceHandler: PersistenceHandling
    let preferencesService: PreferencesService
    let repository: JournalRepository
    let imageStorage: ImageStorageService
    let pasteboardMonitor: PasteboardMonitorProviding
    
    // MARK: - Utilities
    
    let timeProvider: TimeProvider
    let dayCalculator: TradingDayCalculator
    let messageParser: MessageParser
    
    // MARK: - Navigation & State
    
    let router: AppRouter
    let colorService: TagColorService
    let session: AppSession
    let commands: AppCommands
    
    // MARK: - Initialization
    
    init() {
        // 1. Core Utilities & Storage
        let persistence = UserDefaultsPersistenceHandler()
        self.persistenceHandler = persistence
        self.preferencesService = AppPreferencesService(persistence: persistence)
        
        self.imageStorage = LocalImageStorageService()
        let timeProvider = SystemTimeProvider()
        self.timeProvider = timeProvider
        let dayCalculator = ChicagoTradingDayService()
        self.dayCalculator = dayCalculator
        let messageParser = RegexMessageParser()
        self.messageParser = messageParser
        
        self.pasteboardMonitor = AppPasteboardMonitor()
        
        // 2. Navigation & UI State
        self.router = AppRouter()
        self.colorService = TagColorService(persistence: persistence)
        self.session = AppSession(dayCalculator: dayCalculator, timeProvider: timeProvider)

        // 3. Database & Repository
        let appDb = try! AppDatabase.shared()
        self.repository = GRDBJournalRepository(
            appDb: appDb,
            timeProvider: timeProvider,
            dayCalculator: dayCalculator,
            parser: messageParser
        )
        
        // 4. Command Layer
        self.commands = AppCommands(
            preferences: preferencesService,
            router: router,
            repository: repository,
            imageStorage: imageStorage
        )
        
        // 5. Start Background Services
        if preferencesService.isClipboardMonitoringEnabled {
            self.pasteboardMonitor.startMonitoring()
        }
        
        // 6. Startup Migrations
        performStartupMigrations()
    }
    
    private func performStartupMigrations() {
        let currentVersion = 1
        if preferencesService.lastMigrationVersion < currentVersion {
            Task {
                do {
                    try await repository.cleanupOrphanedTags()
                    preferencesService.lastMigrationVersion = currentVersion
                    print("DependencyContainer: Completed startup migration v\(currentVersion)")
                } catch {
                    print("DependencyContainer: Failed startup migration: \(error)")
                }
            }
        }
    }
}
