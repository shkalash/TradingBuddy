import Foundation
import GRDB

// The Join Table for our Many-to-Many relationship
public struct EntryTag: Codable, FetchableRecord, PersistableRecord {
    public var entryId: String
    public var tagId: String
}

extension EntryTag: TableRecord, EncodableRecord {
    static let entry = belongsTo(JournalEntry.self)
    static let tag = belongsTo(Tag.self)
}
