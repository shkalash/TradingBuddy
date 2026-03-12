import Testing
import Foundation
import GRDB
@testable import TradingBuddy

@MainActor
struct JournalRepositoryTests {

    func makeSUT(now: Date = Date()) throws -> (GRDBJournalRepository, AppDatabase, MutableTimeProvider) {
        let dbQueue = try DatabaseQueue()
        let appDb = try AppDatabase(dbQueue)
        let timeProvider = MutableTimeProvider(now: now)
        let dayCalculator = ChicagoTradingDayService()
        let parser = RegexMessageParser()
        
        let repo = GRDBJournalRepository(
            appDb: appDb,
            timeProvider: timeProvider,
            dayCalculator: dayCalculator,
            parser: parser
        )
        
        return (repo, appDb, timeProvider)
    }

    @Test("Saving an entry extracts tags and creates correct database relations")
    func testSaveEntry() async throws {
        let (repo, appDb, _) = try makeSUT()
        
        let text = "Shorted /ES and /NQ due to #tilt"
        let entry = try await repo.saveEntry(text: text, imagePath: nil as String?)
        
        #expect(entry.text == text)
        
        try await appDb.dbWriter.read { db in
            let tagsCount = try Tag.fetchCount(db)
            #expect(tagsCount == 3)
            
            let linksCount = try EntryTag.fetchCount(db)
            #expect(linksCount == 3)
        }
        
        let esEntries = try await repo.entries(forTag: "/ES")
        #expect(esEntries.count == 1)
        #expect(esEntries.first?.id == entry.id)
    }

    @Test("Updating an entry changes text and correctly updates tag relations")
    func testUpdateEntry() async throws {
        let (repo, _, _) = try makeSUT()
        
        let entry = try await repo.saveEntry(text: "Long $AAPL", imagePath: nil as String?)
        
        var aaplEntries = try await repo.entries(forTag: "$AAPL")
        #expect(aaplEntries.count == 1)
        
        try await repo.updateEntry(id: entry.id, newText: "Long $TSLA actually", newImagePath: nil)
        
        aaplEntries = try await repo.entries(forTag: "$AAPL")
        #expect(aaplEntries.isEmpty)
        
        let tslaEntries = try await repo.entries(forTag: "$TSLA")
        #expect(tslaEntries.count == 1)
        #expect(tslaEntries.first?.id == entry.id)
    }

    @Test("Fetching entries for a specific trading day groups them correctly")
    func testEntriesForDay() async throws {
        let tz = TimeZone(identifier: "America/Chicago")!
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz
        
        let day1Midday = cal.date(from: DateComponents(year: 2026, month: 3, day: 5, hour: 12))!
        let day1Evening = cal.date(from: DateComponents(year: 2026, month: 3, day: 5, hour: 19))!
        
        let (repo, _, timeProvider) = try makeSUT(now: day1Midday)
        
        _ = try await repo.saveEntry(text: "Midday trade", imagePath: nil as String?)
        
        timeProvider.now = day1Evening
        
        _ = try await repo.saveEntry(text: "Evening post-market thoughts", imagePath: nil as String?)
        
        let tradingDays = try await repo.allTradingDays()
        #expect(tradingDays.count == 2)
        
        let dayCalculator = ChicagoTradingDayService()
        let march5TradingDay = dayCalculator.getTradingDay(for: day1Midday)
        let march6TradingDay = dayCalculator.getTradingDay(for: day1Evening)
        
        let march5Entries = try await repo.entries(for: march5TradingDay)
        #expect(march5Entries.count == 1)
        #expect(march5Entries.first?.text == "Midday trade")
        
        let march6Entries = try await repo.entries(for: march6TradingDay)
        #expect(march6Entries.count == 1)
        #expect(march6Entries.first?.text == "Evening post-market thoughts")
    }

    @Test("Clearing the database wipes all tables")
    func testClearDatabase() async throws {
        let (repo, appDb, _) = try makeSUT()
        
        _ = try await repo.saveEntry(text: "Test $AAPL", imagePath: nil as String?)
        
        try await repo.clearDatabaseOnly()
        
        try await appDb.dbWriter.read { db in
            let entryCount = try JournalEntry.fetchCount(db)
            let tagCount = try Tag.fetchCount(db)
            let linkCount = try EntryTag.fetchCount(db)
            
            #expect(entryCount == 0)
            #expect(tagCount == 0)
            #expect(linkCount == 0)
        }
    }

    @Test("Saving an entry with an image path persists the path correctly")
    func testSaveEntryWithImage() async throws {
        let (repo, _, _) = try makeSUT()
        
        let imagePath = "2026-03-07/test_image.png"
        let entry = try await repo.saveEntry(text: "Entry with image", imagePath: imagePath)
        
        #expect(entry.imagePath == imagePath)
        
        let entries = try await repo.entries(for: entry.tradingDay)
        #expect(entries.first?.imagePath == imagePath)
    }

    @Test("Updating an entry cleans up orphaned tags")
    func testOrphanedTagCleanup() async throws {
        let (repo, appDb, _) = try makeSUT()
        
        _ = try await repo.saveEntry(text: "Entry 1 #tag1", imagePath: nil as String?)
        _ = try await repo.saveEntry(text: "Entry 2 #tag1 #tag2", imagePath: nil as String?)
        
        try await appDb.dbWriter.read { db in
            #expect(try Tag.fetchCount(db) == 2)
        }
        
        let entry1 = try await repo.entries(forTag: "#tag1").first { $0.text.contains("Entry 1") }!
        
        // Update Entry 1 to remove #tag1
        try await repo.updateEntry(id: entry1.id, newText: "Entry 1 updated", newImagePath: nil)
        
        try await appDb.dbWriter.read { db in
            // #tag1 still exists because Entry 2 uses it
            #expect(try Tag.fetchOne(db, key: "#tag1") != nil)
            #expect(try Tag.fetchCount(db) == 2)
        }
        
        let entry2 = try await repo.entries(forTag: "#tag1").first { $0.text.contains("Entry 2") }!
        
        // Update Entry 2 to remove both tags
        try await repo.updateEntry(id: entry2.id, newText: "Entry 2 updated", newImagePath: nil)
        
        try await appDb.dbWriter.read { db in
            // Both tags should be gone now
            #expect(try Tag.fetchCount(db) == 0)
        }
    }

    @Test("Fetching top topic tags returns tags sorted by reference count")
    func testTopTopicTags() async throws {
        let (repo, _, _) = try makeSUT()
        
        // #tag1 used 3 times
        _ = try await repo.saveEntry(text: "Entry #tag1", imagePath: nil as String?)
        _ = try await repo.saveEntry(text: "Entry #tag1 again", imagePath: nil as String?)
        _ = try await repo.saveEntry(text: "Entry #tag1 once more", imagePath: nil as String?)
        
        // #tag2 used 1 time
        _ = try await repo.saveEntry(text: "Entry with #tag2", imagePath: nil as String?)
        
        // #tag3 used 2 times
        _ = try await repo.saveEntry(text: "Entry #tag3", imagePath: nil as String?)
        _ = try await repo.saveEntry(text: "Entry #tag3 again", imagePath: nil as String?)
        
        // $AAPL used 5 times (should be ignored because it's a ticker, not a topic)
        _ = try await repo.saveEntry(text: "$AAPL $AAPL $AAPL $AAPL $AAPL", imagePath: nil as String?)
        
        let topTags = try await repo.topTopicTags(limit: 2)
        
        #expect(topTags.count == 2)
        #expect(topTags[0].id == "#tag1")
        #expect(topTags[1].id == "#tag3")
    }

    @Test("Saving an entry with duplicate tags should succeed and aggregate them")
    func testDuplicateTagsAggregation() async throws {
        let (repo, appDb, _) = try makeSUT()
        
        let text = "Duplicate tags: #tilt #tilt /ES /ES $AAPL $AAPL"
        let entry = try await repo.saveEntry(text: text, imagePath: nil as String?)
        
        #expect(entry.text == text)
        
        try await appDb.dbWriter.read { db in
            // Should only have 3 tags in the DB: #tilt, /ES, $AAPL
            try #expect(Tag.fetchCount(db) == 3)
            
            // Should only have 3 links in the join table
            try #expect(EntryTag.fetchCount(db) == 3)
        }
    }
}
