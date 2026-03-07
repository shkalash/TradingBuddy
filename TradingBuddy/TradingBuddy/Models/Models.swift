import Foundation
import GRDB

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

public enum TagType: String, Codable {
    case future, ticker, topic
}

public struct Tag: Codable, FetchableRecord, PersistableRecord, Hashable {
    public var id: String // The actual tag text, e.g., "/ES", "$SPY"
    public var type: TagType
    public var lastUsed: Date
}

// The Join Table for our Many-to-Many relationship
public struct EntryTag: Codable, FetchableRecord, PersistableRecord {
    public var entryId: String
    public var tagId: String
}

extension JournalEntry: TableRecord, EncodableRecord {
    // This tells GRDB how to navigate from a JournalEntry to its EntryTags
    static let entryTags = hasMany(EntryTag.self)
    static let tags = hasMany(Tag.self, through: entryTags, using: EntryTag.tag)
}

extension EntryTag: TableRecord, EncodableRecord {
    static let entry = belongsTo(JournalEntry.self)
    static let tag = belongsTo(Tag.self)
}

extension Tag: TableRecord, EncodableRecord {
    static let entryTags = hasMany(EntryTag.self)
    static let entries = hasMany(JournalEntry.self, through: entryTags, using: EntryTag.entry)
}
