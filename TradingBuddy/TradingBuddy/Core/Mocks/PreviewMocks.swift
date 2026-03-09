import Foundation
import SwiftUI
import AppKit
import Combine

/// A collection of mock dependencies for use in SwiftUI Previews.
///
/// **Responsibilities:**
/// - Providing static data for UI prototyping.
/// - Implementing mock repositories and storage services.
/// - Facilitating decoupled View development.
enum PreviewMocks {
    
    // MARK: - Mock Container
    
    @MainActor
    class MockDependencyContainer: AppDependencies {
        let persistenceHandler: PersistenceHandling = MockPersistenceHandler()
        let preferencesService: PreferencesService = MockPreferences()
        let repository: JournalRepository = MockRepo()
        let imageStorage: ImageStorageService = MockImageStorage()
        let timeProvider: TimeProvider = MockTimeProvider()
        let dayCalculator: TradingDayCalculator = ChicagoTradingDayService()
        let messageParser: MessageParser = RegexMessageParser()
        let router: AppRouter = AppRouter()
        let colorService: TagColorService
        let session: AppSession
        let commands: AppCommands
        let pasteboardMonitor: PasteboardMonitorProviding = MockPasteboardMonitor()
        
        init() {
            self.colorService = TagColorService(persistence: persistenceHandler)
            self.session = AppSession(dayCalculator: dayCalculator, timeProvider: timeProvider)
            self.commands = AppCommands(
                preferences: preferencesService,
                router: router,
                repository: repository,
                imageStorage: imageStorage
            )
        }
    }
    
    // MARK: - Mock Repository
    
    class MockRepo: JournalRepository {
        init() {}
        func saveEntry(text: String, imagePath: String?, date: Date?) async throws -> JournalEntry {
            JournalEntry(id: UUID().uuidString, text: text, timestamp: Date(), tradingDay: Date(), imagePath: imagePath)
        }
        func updateEntry(id: String, newText: String, newImagePath: String?) async throws {}
        func entry(id: String) async throws -> JournalEntry? { nil }
        func entries(for day: Date) async throws -> [JournalEntry] {
            [
                JournalEntry(id: "1", text: "Mock entry for /ES", timestamp: Date(), tradingDay: day),
                JournalEntry(id: "2", text: "Mock entry for $AAPL", timestamp: Date().addingTimeInterval(60), tradingDay: day)
            ]
        }
        func allTradingDays() async throws -> [Date] { [Date(), Date().addingTimeInterval(-86400)] }
        func allTags() async throws -> [Tag] {
            [
                Tag(id: "/ES", type: .future, lastUsed: Date()),
                Tag(id: "$AAPL", type: .ticker, lastUsed: Date()),
                Tag(id: "#tilt", type: .topic, lastUsed: Date())
            ]
        }
        func entries(forTag tagId: String) async throws -> [JournalEntry] {
            [JournalEntry(id: "1", text: "Tag entry for \(tagId)", timestamp: Date(), tradingDay: Date())]
        }
        func topTopicTags(limit: Int) async throws -> [Tag] {
            [
                Tag(id: "#HVC_Level", type: .topic, lastUsed: Date()),
                Tag(id: "#size_3+", type: .topic, lastUsed: Date()),
                Tag(id: "#wait_5m", type: .topic, lastUsed: Date())
            ]
        }
        func cleanupOrphanedTags() async throws {}
        func clearDatabaseOnly() async throws {}
        func clearDatabaseAndImages() async throws {}
    }
    
    // MARK: - Mock Services
    
    class MockImageStorage: ImageStorageService {
        init() {}
        func saveImage(_ image: NSImage, date: Date) async throws -> String { "" }
        func deleteImage(at relativePath: String) async throws {}
        func getFileURL(for relativePath: String) -> URL { URL(fileURLWithPath: "") }
        func clearAllImages() throws {}
        func getBaseDirectory() -> URL { URL(fileURLWithPath: "/") }
    }
    
    class MockTimeProvider: TimeProvider {
        init() {}
        var now: Date { Date() }
    }
    
    @Observable
    class MockPreferences: PreferencesService {
        var chatFontSize: Double = 14.0
        var isClipboardMonitoringEnabled: Bool = true
        var forceFocusChatOnImageIntake: Bool = true
        var lastMigrationVersion: Int = 0
        init() {}
        var showHistoryJumpWarning: Bool = true
        var rolloverPromptDelayHours: Int = 2
        var snoozedUntil: Date? = nil
    }

    class MockPersistenceHandler: PersistenceHandling {
        init() {}
        func saveCodable<T: Codable>(object: T?, for key: PersistenceKey<T>) {}
        func loadCodable<T: Codable>(for key: PersistenceKey<T>) -> T? { nil }
        func save<T>(value: T?, for key: PersistenceKey<T>) {}
        func load<T>(for key: PersistenceKey<T>) -> T? { nil }
    }
    
    class MockPasteboardMonitor: PasteboardMonitorProviding {
        var imagePublisher: AnyPublisher<NSImage, Never> { Empty().eraseToAnyPublisher() }
        func startMonitoring() {}
        func stopMonitoring() {}
    }
    
    // MARK: - Factories
    
    /// A helper to create a fully configured ChatViewModel for previews.
    static func makeChatViewModel(dependencies: any AppDependencies) -> ChatViewModel {
        ChatViewModel(dependencies: dependencies)
    }
}
