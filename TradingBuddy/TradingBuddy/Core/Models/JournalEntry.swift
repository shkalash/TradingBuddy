import Foundation
import GRDB

/// A pure data model representing a single trading note or event.
///
/// **Responsibilities:**
/// - Storing raw text, timestamps, and associated metadata.
/// - Defining relationships to `Tag` objects for persistence.
public struct JournalEntry: Codable, FetchableRecord, PersistableRecord, Identifiable, Hashable {
    public var id: String // UUID string
    public var text: String
    public var timestamp: Date // Exact UTC time of the entry
    public var tradingDay: Date // 00:00:00 UTC of the calculated trading day
    public var imagePath: String?
    
    public init(id: String = UUID().uuidString, text: String, timestamp: Date, tradingDay: Date, imagePath: String? = nil) {
        self.id = id
        self.text = text
        self.timestamp = timestamp
        self.tradingDay = tradingDay
        self.imagePath = imagePath
    }
}

extension JournalEntry: TableRecord, EncodableRecord {
    // This tells GRDB how to navigate from a JournalEntry to its EntryTags
    static let entryTags = hasMany(EntryTag.self)
    static let tags = hasMany(Tag.self, through: entryTags, using: EntryTag.tag)
}
