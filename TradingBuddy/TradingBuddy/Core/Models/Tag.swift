import Foundation
import GRDB

public struct Tag: Codable, FetchableRecord, PersistableRecord, Hashable {
    public var id: String // The actual tag text, e.g., "/ES", "$SPY"
    public var type: TagType
    public var lastUsed: Date
}

extension Tag: TableRecord, EncodableRecord {
    static let entryTags = hasMany(EntryTag.self)
    static let entries = hasMany(JournalEntry.self, through: entryTags, using: EntryTag.entry)
}
