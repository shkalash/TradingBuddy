import Foundation

/// The gateway for all journal-related persistence and retrieval logic.
///
/// **Responsibilities:**
/// - Abstracting the underlying storage mechanism (e.g., GRDB).
/// - Managing many-to-many relationships between entries and tags.
/// - Providing unified access to trading day history and tag usage.
public protocol JournalRepository {
    /// Saves a new entry. If `date` is provided, it uses that as the timestamp/trading day basis (useful for historical edits or snoozed rollovers).
    func saveEntry(text: String, imagePath: String?, date: Date?) async throws -> JournalEntry
    
    func updateEntry(id: String, newText: String) async throws
    func entries(for day: Date) async throws -> [JournalEntry]
    func allTradingDays() async throws -> [Date]
    func allTags() async throws -> [Tag]
    func entries(forTag tagId: String) async throws -> [JournalEntry]
    func topTopicTags(limit: Int) async throws -> [Tag]
    func cleanupOrphanedTags() async throws
    func clearDatabaseOnly() async throws
    func clearDatabaseAndImages() async throws
}
