import Foundation
import AppKit
import SwiftUI
@testable import TradingBuddy

// MARK: - Test Shared Mocks

@MainActor
class TestDependencyContainer: AppDependencies {
    var persistenceHandler: PersistenceHandling
    var preferencesService: PreferencesService
    var repository: JournalRepository
    var imageStorage: ImageStorageService
    var timeProvider: TimeProvider
    var dayCalculator: TradingDayCalculator
    var messageParser: MessageParser
    var router: AppRouter
    var colorService: TagColorService
    var session: AppSession
    var commands: AppCommands
    
    init(
        persistenceHandler: PersistenceHandling = PreviewMocks.MockPersistenceHandler(),
        preferencesService: PreferencesService = PreviewMocks.MockPreferences(),
        repository: JournalRepository? = nil,
        imageStorage: ImageStorageService = PreviewMocks.MockImageStorage(),
        timeProvider: TimeProvider = PreviewMocks.MockTimeProvider(),
        dayCalculator: TradingDayCalculator = ChicagoTradingDayService(),
        messageParser: MessageParser = RegexMessageParser(),
        router: AppRouter = AppRouter()
    ) {
        self.persistenceHandler = persistenceHandler
        self.preferencesService = preferencesService
        self.imageStorage = imageStorage
        self.timeProvider = timeProvider
        self.dayCalculator = dayCalculator
        self.messageParser = messageParser
        self.router = router
        self.colorService = TagColorService(persistence: persistenceHandler)
        self.session = AppSession(dayCalculator: dayCalculator, timeProvider: timeProvider)
        
        let repo = repository ?? MockJournalRepository(timeProvider: timeProvider, dayCalculator: dayCalculator)
        self.repository = repo
        
        self.commands = AppCommands(
            preferences: preferencesService,
            router: router,
            repository: repo,
            imageStorage: imageStorage
        )
    }
}

class MutableTimeProvider: TimeProvider {
    var now: Date
    init(now: Date) { self.now = now }
}

class MockJournalRepository: JournalRepository {
    var mockEntries: [JournalEntry] = []
    let timeProvider: TimeProvider
    let dayCalculator: TradingDayCalculator
    
    init(timeProvider: TimeProvider, dayCalculator: TradingDayCalculator) {
        self.timeProvider = timeProvider
        self.dayCalculator = dayCalculator
    }
    
    func saveEntry(text: String, imagePath: String?, date: Date? = nil) async throws -> JournalEntry {
        let timestamp = date ?? timeProvider.now
        
        let tradingDay: Date
        if let explicitDate = date {
            tradingDay = explicitDate
        } else {
            tradingDay = dayCalculator.getTradingDay(for: timestamp)
        }
        
        let entry = JournalEntry(text: text, timestamp: timestamp, tradingDay: tradingDay, imagePath: imagePath)
        mockEntries.append(entry)
        return entry
    }
    func updateEntry(id: String, newText: String) async throws {
        if let index = mockEntries.firstIndex(where: { $0.id == id }) {
            mockEntries[index].text = newText
        }
    }
    func entries(for day: Date) async throws -> [JournalEntry] { 
        return mockEntries.filter { $0.tradingDay == day } 
    }
    func allTradingDays() async throws -> [Date] { [] }
    func allTags() async throws -> [TradingBuddy.Tag] { [] }
    func entries(forTag tagId: String) async throws -> [JournalEntry] { [] }
    func clearDatabaseOnly() async throws { mockEntries.removeAll() }
    func clearDatabaseAndImages() async throws { mockEntries.removeAll() }
}
