import Foundation
import GRDB

/// The concrete implementation of `JournalRepository` using GRDB for SQLite persistence.
///
/// **Responsibilities:**
/// - Executing SQL queries and mapping results to `JournalEntry` and `Tag` models.
/// - Managing many-to-many join table operations for tags.
/// - Broadcasting `databaseUpdated` and `databaseCleared` notifications.
/// - Providing debug seeding utilities for development environments.
public class GRDBJournalRepository: JournalRepository {
    // MARK: - Properties
    
    private let appDb: AppDatabase
    private let timeProvider: TimeProvider
    private let dayCalculator: TradingDayCalculator
    private let parser: MessageParser
    
    // MARK: - Initialization
    
    public init(appDb: AppDatabase, timeProvider: TimeProvider, dayCalculator: TradingDayCalculator, parser: MessageParser) {
        self.appDb = appDb
        self.timeProvider = timeProvider
        self.dayCalculator = dayCalculator
        self.parser = parser
    }
    
    // MARK: - JournalRepository Implementation
    
    public func saveEntry(text: String, imagePath: String?, date: Date? = nil) async throws -> JournalEntry {
        let currentRealTime = date ?? timeProvider.now
        let calculatedDay = dayCalculator.getTradingDay(for: currentRealTime)
        let extractedTags = parser.extractTags(from: text)
        
        let savedEntry = try await appDb.dbWriter.write { db -> JournalEntry in
            let newEntry = JournalEntry(
                id: UUID().uuidString,
                text: text,
                timestamp: currentRealTime,
                tradingDay: calculatedDay,
                imagePath: imagePath
            )
            
            try newEntry.insert(db)
            
            for pt in extractedTags {
                let tag = Tag(id: pt.id, type: pt.type, lastUsed: currentRealTime)
                try tag.save(db)
                
                let entryTag = EntryTag(entryId: newEntry.id, tagId: tag.id)
                try entryTag.insert(db)
            }
            
            return newEntry
        }
        
        await MainActor.run {
            NotificationCenter.default.post(name: .databaseUpdated, object: nil)
        }
        
        return savedEntry
    }
    
    public func updateEntry(id: String, newText: String) async throws {
        let now = timeProvider.now
        let parsedTags = parser.extractTags(from: newText)
        
        try await appDb.dbWriter.write { db in
            guard var entry = try JournalEntry.fetchOne(db, key: id) else { return }
            
            entry.text = newText
            try entry.update(db)
            
            try EntryTag.filter(Column("entryId") == id).deleteAll(db)
            
            for pTag in parsedTags {
                if var existingTag = try Tag.fetchOne(db, key: pTag.id) {
                    existingTag.lastUsed = now
                    try existingTag.update(db)
                } else {
                    let newTag = Tag(id: pTag.id, type: pTag.type, lastUsed: now)
                    try newTag.insert(db)
                }
                
                let link = EntryTag(entryId: id, tagId: pTag.id)
                try link.save(db)
            }
        }
        
        await MainActor.run {
            NotificationCenter.default.post(name: .databaseUpdated, object: nil)
        }
    }
    
    public func entries(for day: Date) async throws -> [JournalEntry] {
        try await appDb.dbWriter.read { db in
            try JournalEntry
                .filter(Column("tradingDay") == day)
                .order(Column("timestamp").asc)
                .fetchAll(db)
        }
    }
    
    public func allTradingDays() async throws -> [Date] {
        try await appDb.dbWriter.read { db in
            let request = JournalEntry
                .select(Column("tradingDay"))
                .distinct()
                .order(Column("tradingDay").desc)
            
            return try Date.fetchAll(db, request)
        }
    }
    
    public func allTags() async throws -> [Tag] {
        try await appDb.dbWriter.read { db in
            try Tag.order(Column("lastUsed").desc).fetchAll(db)
        }
    }
    
    public func entries(forTag tagId: String) async throws -> [JournalEntry] {
        try await appDb.dbWriter.read { db in
            try JournalEntry
                .joining(required: JournalEntry.tags.filter(Column("id") == tagId))
                .order(Column("timestamp").asc)
                .fetchAll(db)
        }
    }
    
    public func clearDatabaseOnly() async throws {
        try await appDb.dbWriter.write { db in
            try EntryTag.deleteAll(db)
            try Tag.deleteAll(db)
            try JournalEntry.deleteAll(db)
        }
        
        await MainActor.run {
            NotificationCenter.default.post(name: .databaseCleared, object: nil)
        }
    }
    
    public func clearDatabaseAndImages() async throws {
        try await clearDatabaseOnly()
        
        let imagesDir = AppStoragePaths.imagesDirectory
        if let files = try? FileManager.default.contentsOfDirectory(at: imagesDir, includingPropertiesForKeys: nil) {
            for file in files {
                try? FileManager.default.removeItem(at: file)
            }
        }
    }
}

// MARK: - Debug Seeding

#if DEBUG

struct RawSeedTag: Sendable {
    let id: String
    let type: TagType
}

struct RawSeedData: Sendable {
    let id: String
    let text: String
    let timestamp: Date
    let tradingDay: Date
    let tags: [RawSeedTag]
}

extension GRDBJournalRepository {
    @MainActor
    public func debugPopulate() async throws {
        let calendar = Calendar.current
        let today = Date()
        let sampleTags = ["/ES", "/NQ", "$AAPL", "$SPY", "#tilt", "#fomo", "#review", "#strategy", "#patience"]
        
        var tempRecords: [RawSeedData] = []
        
        let recentOffsets = (0..<5).map { _ in Int.random(in: 0...20) }
        let historyOffsets = (0..<35).map { _ in Int.random(in: 30...1000) }
        let allOffsets = Array(Set(recentOffsets + historyOffsets)).sorted(by: >)
        
        for dayOffset in allOffsets {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            let startOfDay = calendar.startOfDay(for: date)
            
            let entriesCount = Int.random(in: 2...6)
            
            for i in 0..<entriesCount {
                let tag1 = sampleTags.randomElement()!
                let tag2 = sampleTags.randomElement()!
                let text = "Debug trade note \(i) for \(date.formatted(.dateTime.year().month().day())): Watched \(tag1) closely. Felt a bit of \(tag2)."
                
                let randomSeconds = TimeInterval(Int.random(in: 28800...57600))
                let entryTimestamp = startOfDay.addingTimeInterval(randomSeconds)
                
                let tradingDay = dayCalculator.getTradingDay(for: entryTimestamp)
                let parsedTags = parser.extractTags(from: text)
                let rawTags = parsedTags.map { RawSeedTag(id: $0.id, type: $0.type) }
                
                tempRecords.append(RawSeedData(
                    id: UUID().uuidString,
                    text: text,
                    timestamp: entryTimestamp,
                    tradingDay: tradingDay,
                    tags: rawTags
                ))
            }
        }
        
        let recordsToInsert = tempRecords
        
        try await appDb.dbWriter.write { db in
            for record in recordsToInsert {
                let newEntry = JournalEntry(
                    id: record.id,
                    text: record.text,
                    timestamp: record.timestamp,
                    tradingDay: record.tradingDay,
                    imagePath: nil
                )
                try newEntry.insert(db)
                
                for rt in record.tags {
                    let tag = Tag(id: rt.id, type: rt.type, lastUsed: newEntry.timestamp)
                    try? tag.save(db)
                    
                    let entryTag = EntryTag(entryId: newEntry.id, tagId: tag.id)
                    try? entryTag.insert(db)
                }
            }
        }
    }
}
#endif
