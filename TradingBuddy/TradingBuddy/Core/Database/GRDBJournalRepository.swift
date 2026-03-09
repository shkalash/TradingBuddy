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
    
    init(
        appDb: AppDatabase,
        timeProvider: TimeProvider,
        dayCalculator: TradingDayCalculator,
        parser: MessageParser
    ) {
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
            NotificationCenter.default.post(name: AppConstants.Notifications.databaseUpdated, object: nil)
        }
        
        return savedEntry
    }
    
    public func updateEntry(id: String, newText: String) async throws {
        let now = timeProvider.now
        let parsedTags = parser.extractTags(from: newText)
        
        try await appDb.dbWriter.write { db in
            guard var entry = try JournalEntry.fetchOne(db, key: id) else { return }
            
            // 1. Capture old tags to check for orphans later
            let oldTagIds = try Tag.joining(required: Tag.entryTags.filter(Column(AppConstants.Database.Columns.entryId) == id))
                .fetchAll(db)
                .map { $0.id }
            
            entry.text = newText
            try entry.update(db)
            
            // 2. Remove all existing links for this entry
            try EntryTag.filter(Column(AppConstants.Database.Columns.entryId) == id).deleteAll(db)
            
            // 3. Create new tags and links
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
            
            // 4. Cleanup orphaned tags (tags with no more entries)
            for oldTagId in oldTagIds {
                let count = try EntryTag.filter(Column(AppConstants.Database.Columns.tagId) == oldTagId).fetchCount(db)
                if count == 0 {
                    try Tag.filter(Column(AppConstants.Database.Columns.id) == oldTagId).deleteAll(db)
                }
            }
        }
        
        await MainActor.run {
            NotificationCenter.default.post(name: AppConstants.Notifications.databaseUpdated, object: nil)
        }
    }
    
    public func entries(for day: Date) async throws -> [JournalEntry] {
        try await appDb.dbWriter.read { db in
            try JournalEntry
                .filter(Column(AppConstants.Database.Columns.tradingDay) == day)
                .order(Column(AppConstants.Database.Columns.timestamp).asc)
                .fetchAll(db)
        }
    }
    
    public func allTradingDays() async throws -> [Date] {
        try await appDb.dbWriter.read { db in
            let request = JournalEntry
                .select(Column(AppConstants.Database.Columns.tradingDay))
                .distinct()
                .order(Column(AppConstants.Database.Columns.tradingDay).desc)
            
            return try Date.fetchAll(db, request)
        }
    }
    
    public func allTags() async throws -> [Tag] {
        try await appDb.dbWriter.read { db in
            try Tag.order(Column(AppConstants.Database.Columns.lastUsed).desc).fetchAll(db)
        }
    }
    
    public func entries(forTag tagId: String) async throws -> [JournalEntry] {
        try await appDb.dbWriter.read { db in
            try JournalEntry
                .joining(required: JournalEntry.tags.filter(Column(AppConstants.Database.Columns.id) == tagId))
                .order(Column(AppConstants.Database.Columns.timestamp).asc)
                .fetchAll(db)
        }
    }
    
    public func topTopicTags(limit: Int) async throws -> [Tag] {
        try await appDb.dbWriter.read { db in
            let sql = """
            SELECT tag.*
            FROM tag
            JOIN entryTag ON tag.id = entryTag.tagId
            WHERE tag.type = ?
            GROUP BY tag.id
            ORDER BY COUNT(entryTag.tagId) DESC
            LIMIT ?
            """
            return try Tag.fetchAll(db, sql: sql, arguments: [TagType.topic.rawValue, limit])
        }
    }
    
    public func cleanupOrphanedTags() async throws {
        try await appDb.dbWriter.write { db in
            let allTags = try Tag.fetchAll(db)
            for tag in allTags {
                let count = try EntryTag.filter(Column(AppConstants.Database.Columns.tagId) == tag.id).fetchCount(db)
                if count == 0 {
                    try Tag.filter(Column(AppConstants.Database.Columns.id) == tag.id).deleteAll(db)
                }
            }
        }
    }
    
    public func clearDatabaseOnly() async throws {
        try await appDb.dbWriter.write { db in
            try EntryTag.deleteAll(db)
            try Tag.deleteAll(db)
            try JournalEntry.deleteAll(db)
        }
        
        await MainActor.run {
            NotificationCenter.default.post(name: AppConstants.Notifications.databaseCleared, object: nil)
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
        let messages = DebugSeedData.messages.shuffled() // Randomize order every time
        
        var tempRecords: [RawSeedData] = []
        var messageIndex = 0
        
        // Distribution Strategy:
        // 1. Recent: Last 7 days get ~50% of messages (heavier volume)
        // 2. History: Last 90 days get ~50% of messages (scattered)
        
        let recentDays = (0..<7).map { $0 }
        let historyDays = (7..<90).map { $0 }
        
        // Populate Recent (High Volume)
        for dayOffset in recentDays {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            let startOfDay = calendar.startOfDay(for: date)
            
            // 3-8 messages per recent day
            let dailyVolume = Int.random(in: 3...8)
            
            for _ in 0..<dailyVolume {
                if messageIndex >= messages.count { messageIndex = 0 } // Recycle if needed
                let text = messages[messageIndex]
                messageIndex += 1
                
                // Random time between 8:00 AM and 4:00 PM
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
        
        // Populate History (Sparse Volume)
        // Pick ~15 random days from history to populate
        let selectedHistoryDays = historyDays.shuffled().prefix(15)
        
        for dayOffset in selectedHistoryDays {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            let startOfDay = calendar.startOfDay(for: date)
            
            // 1-3 messages per historical day
            let dailyVolume = Int.random(in: 1...3)
            
            for _ in 0..<dailyVolume {
                if messageIndex >= messages.count { messageIndex = 0 }
                let text = messages[messageIndex]
                messageIndex += 1
                
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
        
        let recordsToInsert = tempRecords.sorted { $0.timestamp < $1.timestamp }
        
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
                    // Update tag lastUsed if it's newer
                    if var existingTag = try Tag.fetchOne(db, key: rt.id) {
                        if record.timestamp > existingTag.lastUsed {
                            existingTag.lastUsed = record.timestamp
                            try existingTag.update(db)
                        }
                    } else {
                        let tag = Tag(id: rt.id, type: rt.type, lastUsed: record.timestamp)
                        try tag.insert(db)
                    }
                    
                    let entryTag = EntryTag(entryId: newEntry.id, tagId: rt.id)
                    try entryTag.insert(db)
                }
            }
        }
    }
}
#endif
