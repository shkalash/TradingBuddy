import Foundation
import GRDB

/// A model representing a financial identifier or topic tag.
///
/// **Responsibilities:**
/// - Storing the unique identifier (e.g., "/ES", "$AAPL") and its category.
/// - Tracking usage history for sorting and recency logic.
/// - Defining database relationships back to journal entries.
public struct Tag: Codable, FetchableRecord, PersistableRecord, Hashable, Identifiable {
    // MARK: - Properties
    
    public var id: String // The actual tag text, e.g., "/ES", "$SPY"
    public var type: TagType
    public var lastUsed: Date
    
    // MARK: - Initialization
    
    public init(id: String, type: TagType, lastUsed: Date) {
        self.id = id
        self.type = type
        self.lastUsed = lastUsed
    }
}

extension Tag: TableRecord, EncodableRecord {
    static let entryTags = hasMany(EntryTag.self)
    static let entries = hasMany(JournalEntry.self, through: entryTags, using: EntryTag.entry)
}
