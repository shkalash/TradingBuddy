import Foundation

public protocol JournalRepository {
    func saveEntry(text: String, imagePath: String?) async throws -> JournalEntry
    func updateEntry(id: String, newText: String) async throws
    func entries(for day: Date) async throws -> [JournalEntry]
    func allTradingDays() async throws -> [Date]
    func allTags() async throws -> [Tag]
    func entries(forTag tagId: String) async throws -> [JournalEntry]
    func clearDatabaseOnly() async throws
    func clearDatabaseAndImages() async throws
}
