import Foundation
import AppKit
import SwiftUI
import Combine
@testable import TradingBuddy

// MARK: - MutableTimeProvider

/// A mutable TimeProvider for tests. Marked @unchecked Sendable because `now`
/// is only mutated from the test's main actor context — safe in practice.
class MutableTimeProvider: TimeProvider, @unchecked Sendable {
    var now: Date
    init(now: Date) { self.now = now }
}

// MARK: - MockPersistenceHandler

class MockPersistenceHandler: PersistenceHandling {
    var storage: [String: Any] = [:]

    func saveCodable<T: Codable>(object: T?, for key: PersistenceKey<T>) {
        if let object = object {
            storage[key.name] = try? JSONEncoder().encode(object)
        } else {
            storage.removeValue(forKey: key.name)
        }
    }

    func loadCodable<T: Codable>(for key: PersistenceKey<T>) -> T? {
        guard let data = storage[key.name] as? Data else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    func save<T>(value: T?, for key: PersistenceKey<T>) {
        storage[key.name] = value
    }

    func load<T>(for key: PersistenceKey<T>) -> T? {
        storage[key.name] as? T
    }
}

// MARK: - MockJournalRepository

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

    /// Returns entries whose text contains the tagId string.
    /// Best-effort mock — real tag-relation filtering is covered by JournalRepositoryTests (GRDB).
    func entries(forTag tagId: String) async throws -> [JournalEntry] {
        mockEntries.filter { $0.text.contains(tagId) }
    }

    func topTopicTags(limit: Int) async throws -> [Tag] { [] }

    func cleanupOrphanedTags() async throws {}

    func clearDatabaseOnly() async throws { mockEntries.removeAll() }

    func clearDatabaseAndImages() async throws { mockEntries.removeAll() }
}

// MARK: - TestDependencyContainer

// Default parameter expressions cannot call @MainActor-isolated inits from a
// nonisolated context in Swift 6. Remove all defaults that invoke @MainActor
// types and require callers to supply them explicitly (or use the @MainActor
// factory below).
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
    var pasteboardMonitor: PasteboardMonitorProviding

    init(
        persistenceHandler: PersistenceHandling,
        preferencesService: PreferencesService,
        repository: JournalRepository,
        imageStorage: ImageStorageService,
        timeProvider: TimeProvider,
        dayCalculator: TradingDayCalculator,
        messageParser: MessageParser,
        router: AppRouter
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
        self.pasteboardMonitor = PreviewMocks.MockPasteboardMonitor()
        self.repository = repository

        self.commands = AppCommands(
            preferences: preferencesService,
            router: router,
            repository: repository,
            imageStorage: imageStorage
        )
    }

    /// Convenience factory — all @MainActor-isolated inits called safely here.
    static func make(
        timeProvider: TimeProvider,
        repository: JournalRepository? = nil,
        preferencesService: PreferencesService? = nil,
        router: AppRouter? = nil
    ) -> TestDependencyContainer {
        let prefs = preferencesService ?? PreviewMocks.MockPreferences()
        let tp    = timeProvider
        let dc    = ChicagoTradingDayService()
        let repo  = repository ?? MockJournalRepository(timeProvider: tp, dayCalculator: dc)
        let r     = router ?? AppRouter()

        return TestDependencyContainer(
            persistenceHandler: PreviewMocks.MockPersistenceHandler(),
            preferencesService: prefs,
            repository: repo,
            imageStorage: PreviewMocks.MockImageStorage(),
            timeProvider: tp,
            dayCalculator: dc,
            messageParser: RegexMessageParser(),
            router: r
        )
    }
}
