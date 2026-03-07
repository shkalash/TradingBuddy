import Foundation
import SwiftUI
import AppKit

/// A collection of mock dependencies for use in SwiftUI Previews.
///
/// **Responsibilities:**
/// - Providing static data for UI prototyping.
/// - Implementing mock repositories and storage services.
/// - Facilitating decoupled View development.
public enum PreviewMocks {
    
    // MARK: - Mock Repository
    
    public class MockRepo: JournalRepository {
        public init() {}
        public func saveEntry(text: String, imagePath: String?, date: Date?) async throws -> JournalEntry {
            JournalEntry(id: UUID().uuidString, text: text, timestamp: Date(), tradingDay: Date(), imagePath: imagePath)
        }
        public func updateEntry(id: String, newText: String) async throws {}
        public func entries(for day: Date) async throws -> [JournalEntry] {
            [
                JournalEntry(id: "1", text: "Mock entry for /ES", timestamp: Date(), tradingDay: day),
                JournalEntry(id: "2", text: "Mock entry for $AAPL", timestamp: Date().addingTimeInterval(60), tradingDay: day)
            ]
        }
        public func allTradingDays() async throws -> [Date] { [Date(), Date().addingTimeInterval(-86400)] }
        public func allTags() async throws -> [Tag] {
            [
                Tag(id: "/ES", type: .future, lastUsed: Date()),
                Tag(id: "$AAPL", type: .ticker, lastUsed: Date()),
                Tag(id: "#tilt", type: .topic, lastUsed: Date())
            ]
        }
        public func entries(forTag tagId: String) async throws -> [JournalEntry] {
            [JournalEntry(id: "1", text: "Tag entry for \(tagId)", timestamp: Date(), tradingDay: Date())]
        }
        public func clearDatabaseOnly() async throws {}
        public func clearDatabaseAndImages() async throws {}
    }
    
    // MARK: - Mock Services
    
    public class MockImageStorage: ImageStorageService {
        public init() {}
        public func saveImage(_ image: NSImage, date: Date) async throws -> String { "" }
        public func getFileURL(for relativePath: String) -> URL { URL(fileURLWithPath: "") }
        public func clearAllImages() throws {}
        public func getBaseDirectory() -> URL { URL(fileURLWithPath: "/") }
    }
    
    public class MockTimeProvider: TimeProvider {
        public init() {}
        public var now: Date { Date() }
    }
    
    public class MockPreferences: PreferencesService {
        public init() {}
        public var showHistoryJumpWarning: Bool = true
        public var rolloverPromptDelayHours: Int = 2
        public var snoozedUntil: Date? = nil
    }
    
    // MARK: - Factories
    
    /// A helper to create a fully configured ChatViewModel for previews.
    public static func makeChatViewModel() -> ChatViewModel {
        ChatViewModel(
            repository: MockRepo(),
            timeProvider: MockTimeProvider(),
            dayCalculator: ChicagoTradingDayService(),
            preferences: MockPreferences(),
            router: AppRouter(),
            imageStorage: MockImageStorage()
        )
    }
}
