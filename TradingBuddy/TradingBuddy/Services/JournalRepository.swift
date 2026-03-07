//
//  JournalRepository.swift
//  TradingBuddy
//
//  Created by Shai Kalev on 3/6/26.
//


import Foundation
import GRDB

public protocol JournalRepository {
    func saveEntry(text: String, imagePath: String?) async throws -> JournalEntry
    func updateEntry(id: String, newText: String) async throws
    func entries(for day: Date) async throws -> [JournalEntry]
    func allTradingDays() async throws -> [Date]
    func allTags() async throws -> [Tag]
    func entries(forTag tagId: String) async throws -> [JournalEntry]
    func clearDatabase() async throws
}

public class GRDBJournalRepository: JournalRepository {
    private let appDb: AppDatabase
    private let timeProvider: TimeProvider
    private let dayCalculator: TradingDayCalculator
    private let parser: MessageParser
    
    public init(appDb: AppDatabase, timeProvider: TimeProvider, dayCalculator: TradingDayCalculator, parser: MessageParser) {
        self.appDb = appDb
        self.timeProvider = timeProvider
        self.dayCalculator = dayCalculator
        self.parser = parser
    }
    
    public func saveEntry(text: String, imagePath: String?) async throws -> JournalEntry {
        let currentRealTime = timeProvider.now
        let calculatedDay = dayCalculator.getTradingDay(for: currentRealTime)
        let extractedTags = parser.extractTags(from: text)
        
        // FIX: Create and modify the entry INSIDE the closure so Swift 6 doesn't complain
        let savedEntry = try await appDb.dbWriter.write { db -> JournalEntry in
            let newEntry = JournalEntry(
                id: UUID().uuidString,
                text: text,
                timestamp: currentRealTime,
                tradingDay: calculatedDay,
                imagePath: imagePath
            )
            
            try newEntry.insert(db)
            
            // Handle tags
            for pt in extractedTags {
                let tag = Tag(id: pt.id, type: pt.type, lastUsed: currentRealTime)
                try tag.save(db) // Upserts the tag
                
                let entryTag = EntryTag(entryId: newEntry.id, tagId: tag.id)
                try entryTag.insert(db)
            }
            
            return newEntry
        }
        
        return savedEntry
    }
    
    public func updateEntry(id: String, newText: String) async throws {
        let now = timeProvider.now
        let parsedTags = parser.extractTags(from: newText)
        
        try await appDb.dbWriter.write { db in
            guard var entry = try JournalEntry.fetchOne(db, key: id) else { return }
            
            // 1. Update entry text
            entry.text = newText
            try entry.update(db)
            
            // 2. Clear out old tag links for this entry
            try EntryTag.filter(Column("entryId") == id).deleteAll(db)
            
            // 3. Re-link the new tags
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
            // Tell GRDB to fetch Dates directly from the selected column
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
            // This uses the 'tags' association we defined in Models.swift!
            try JournalEntry
                .joining(required: JournalEntry.tags.filter(Column("id") == tagId))
                .order(Column("timestamp").asc)
                .fetchAll(db)
        }
    }
    public func clearDatabase() async throws {
        try await appDb.dbWriter.write { db in
            // Must delete child tables first to respect foreign keys (even though cascade is on, it's safer)
            try EntryTag.deleteAll(db)
            try Tag.deleteAll(db)
            try JournalEntry.deleteAll(db)
        }
    }
}
// MARK: - Debug
#if DEBUG

// 1. Pure data structs using strictly Sendable primitives to cross the thread boundary safely.
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
    public func debugPopulate() async throws {
        let calendar = Calendar.current
        let today = Date()
        let sampleTags = ["/ES", "/NQ", "$AAPL", "$SPY", "#tilt", "#fomo", "#review", "#strategy", "#patience"]
        
        var tempRecords: [RawSeedData] = []
        
        for dayOffset in 0..<5 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            
            for i in 0..<3 {
                let tag1 = sampleTags.randomElement()!
                let tag2 = sampleTags.randomElement()!
                let text = "Debug trade note \(i) for \(date.formatted(.dateTime.weekday().day())): Watched \(tag1) closely. Felt a bit of \(tag2)."
                
                let entryTimestamp = date.addingTimeInterval(TimeInterval(i * 3600 + 1000))
                
                // Safe to use main-actor parser & dayCalculator here
                let tradingDay = dayCalculator.getTradingDay(for: entryTimestamp)
                let parsedTags = parser.extractTags(from: text)
                
                // Extract just the raw data from the tags
                let rawTags = parsedTags.map { RawSeedTag(id: $0.id, type: $0.type) }
                
                // Store only primitives, do NOT instantiate JournalEntry yet!
                tempRecords.append(RawSeedData(
                    id: UUID().uuidString,
                    text: text,
                    timestamp: entryTimestamp,
                    tradingDay: tradingDay,
                    tags: rawTags
                ))
            }
        }
        
        // Freeze the mutable array into a Sendable 'let' constant
        let recordsToInsert = tempRecords
        
        // Pass only the frozen, primitive data into the database closure
        try await appDb.dbWriter.write { db in
            for record in recordsToInsert {
                // 2. Instantiate JournalEntry entirely INSIDE the background closure
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
