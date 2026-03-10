import Foundation
import AppKit
import SwiftUI
import Combine
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
    var newsService: EconomicNewsServicing
    var pasteboardMonitor: PasteboardMonitorProviding
    
    init(
        persistenceHandler: PersistenceHandling? = nil,
        preferencesService: PreferencesService? = nil,
        repository: JournalRepository? = nil,
        imageStorage: ImageStorageService? = nil,
        timeProvider: TimeProvider? = nil,
        dayCalculator: TradingDayCalculator? = nil,
        messageParser: MessageParser? = nil,
        newsService: EconomicNewsServicing? = nil,
        router: AppRouter? = nil
    ) {
        let ph = persistenceHandler ?? PreviewMocks.MockPersistenceHandler()
        self.persistenceHandler = ph
        
        let prefs = preferencesService ?? PreviewMocks.MockPreferences()
        self.preferencesService = prefs
        
        self.imageStorage = imageStorage ?? PreviewMocks.MockImageStorage()
        
        let tp = timeProvider ?? PreviewMocks.MockTimeProvider()
        self.timeProvider = tp
        
        let dc = dayCalculator ?? ChicagoTradingDayService()
        self.dayCalculator = dc
        
        let mp = messageParser ?? RegexMessageParser()
        self.messageParser = mp
        
        let ns = newsService ?? PreviewMocks.MockNewsService()
        self.newsService = ns
        
        let r = router ?? AppRouter()
        self.router = r
        
        self.colorService = TagColorService(persistence: ph)
        self.session = AppSession(
            dayCalculator: dc,
            timeProvider: tp,
            newsService: ns,
            preferences: prefs
        )
        self.pasteboardMonitor = PreviewMocks.MockPasteboardMonitor()
        
        let repo = repository ?? MockJournalRepository(timeProvider: tp, dayCalculator: dc)
        self.repository = repo
        
        self.commands = AppCommands(
            preferences: prefs,
            router: r,
            repository: repo,
            imageStorage: self.imageStorage
        )
    }
}

@MainActor
final class MutableTimeProvider: TimeProvider {
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
        let tradingDay = dayCalculator.getTradingDay(for: timestamp)
        
        let entry = JournalEntry(text: text, timestamp: timestamp, tradingDay: tradingDay, imagePath: imagePath)
        mockEntries.append(entry)
        return entry
    }
    func updateEntry(id: String, newText: String, newImagePath: String?) async throws {
        if let index = mockEntries.firstIndex(where: { $0.id == id }) {
            mockEntries[index].text = newText
            mockEntries[index].imagePath = newImagePath
        }
    }
    func entry(id: String) async throws -> JournalEntry? {
        mockEntries.first(where: { $0.id == id })
    }
    func entries(for day: Date) async throws -> [JournalEntry] {
        let normalizedDay = dayCalculator.getTradingDay(for: day)
        return mockEntries.filter { $0.tradingDay == normalizedDay }
    }
    func allTradingDays() async throws -> [Date] { [] }
    func allTags() async throws -> [TradingBuddy.Tag] { [] }
    func entries(forTag tagId: String) async throws -> [JournalEntry] { [] }
    func topTopicTags(limit: Int) async throws -> [Tag] { [] }
    func cleanupOrphanedTags() async throws {}
    func clearDatabaseOnly() async throws { mockEntries.removeAll() }
    func clearDatabaseAndImages() async throws { mockEntries.removeAll() }
}
