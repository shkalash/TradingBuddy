import Testing
import Foundation
import GRDB
@testable import TradingBuddy

struct AppDatabaseTests {

    func makeTestDatabase() throws -> AppDatabase {
        let dbQueue = try DatabaseQueue()
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

        try appDb.dbWriter.write { db in
            try entry.insert(db)
        }

        // Use dbReader, not dbWriter, for reads
        let fetchedEntry = try appDb.dbReader.read { db in
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

        // Write initial data in one committed transaction
        try appDb.dbWriter.write { db in
            try entry.insert(db)
            try tag.insert(db)
            try link.insert(db)
        }

        // Verify link exists on committed data, then delete
        let linkCountBefore = try appDb.dbReader.read { db in
            try EntryTag.fetchCount(db)
        }
        #expect(linkCountBefore == 1)

        _ = try appDb.dbWriter.write { db in
            try entry.delete(db)
        }

        // Verify cascade on committed state after delete
        let linkCountAfter = try appDb.dbReader.read { db in
            try EntryTag.fetchCount(db)
        }
        #expect(linkCountAfter == 0)

        // Tag itself must survive — cascade only removes the join row
        let tagCount = try appDb.dbReader.read { db in
            try Tag.fetchCount(db)
        }
        #expect(tagCount == 1)
    }
}
