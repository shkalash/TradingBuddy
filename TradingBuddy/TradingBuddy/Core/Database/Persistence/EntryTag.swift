import Foundation
import GRDB

/// A persistence-only model representing the many-to-many join table between `JournalEntry` and `Tag`.
///
/// **Responsibilities:**
/// - Mapping the relationship between entries and tags in the SQLite database.
/// - Providing GRDB relationship definitions for cross-table queries.
public struct EntryTag: Codable, FetchableRecord, PersistableRecord {
    // MARK: - Properties
    
    public var entryId: String
    public var tagId: String
    
    // MARK: - Relationships
    
    public init(entryId: String, tagId: String) {
        self.entryId = entryId
        self.tagId = tagId
    }
}

extension EntryTag: TableRecord, EncodableRecord {
    static let entry = belongsTo(JournalEntry.self)
    static let tag = belongsTo(Tag.self)
}
