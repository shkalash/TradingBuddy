import Testing
import Foundation
import GRDB
@testable import TradingBuddy

struct AppDatabaseTests {
    
    // Helper to create a fresh, in-memory database for each test
    func makeTestDatabase() throws -> AppDatabase {
        let dbQueue = try DatabaseQueue() // Creates an entirely in-memory SQLite DB
        return try AppDatabase(dbQueue)
    }

    @Test("Can insert and fetch a JournalEntry")
    func testInsertAndFetchJournalEntry() throws {
        let appDb = try makeTestDatabase()
        let now = Date()
        
        let entry = JournalEntry(
            id: "msg-1",
            text: "Testing the database",
            timestamp: now,
            tradingDay: now
        )
        
        // Write to DB
        try appDb.dbWriter.write { db in
            try entry.insert(db)
        }
        
        // Read from DB
        let fetchedEntry = try appDb.dbWriter.read { db in
            try JournalEntry.fetchOne(db, key: "msg-1")
        }
        
        #expect(fetchedEntry != nil)
        #expect(fetchedEntry?.text == "Testing the database")
    }

    @Test("Cascading deletes: Deleting a JournalEntry deletes its EntryTag links")
    func testCascadingDeletes() throws {
        let appDb = try makeTestDatabase()
        let now = Date()
        
        let entry = JournalEntry(id: "msg-2", text: "Trading /ES", timestamp: now, tradingDay: now)
        let tag = Tag(id: "/ES", type: .future, lastUsed: now)
        let link = EntryTag(entryId: "msg-2", tagId: "/ES")
        
        try appDb.dbWriter.write { db in
            // Insert records
            try entry.insert(db)
            try tag.insert(db)
            try link.insert(db)
            
            // Verify link exists
            let linkCountBefore = try EntryTag.fetchCount(db)
            #expect(linkCountBefore == 1)
            
            // Delete the JournalEntry
            try entry.delete(db)
            
            // Verify the link was automatically deleted by SQLite (ON DELETE CASCADE)
            let linkCountAfter = try EntryTag.fetchCount(db)
            #expect(linkCountAfter == 0)
            
            // Verify the Tag itself still exists (we don't want to delete the master tag)
            let tagCount = try Tag.fetchCount(db)
            #expect(tagCount == 1)
        }
    }
}
