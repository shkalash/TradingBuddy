import Foundation
import GRDB

/// The low-level database manager responsible for SQLite connections and schema migrations.
///
/// **Responsibilities:**
/// - Providing a thread-safe `DatabaseWriter` instance.
/// - Defining and executing the database schema and migrations.
/// - Ensuring data integrity through SQL constraints and triggers.
public struct AppDatabase {
    // MARK: - Properties
    
    public let dbWriter: any DatabaseWriter

    /// Use this for all read-only queries. On a DatabasePool this runs
    /// concurrently with writes; on a DatabaseQueue it shares the same
    /// serial queue but is still the correct API to signal intent.
    public var dbReader: any DatabaseReader { dbWriter }
    
    // MARK: - Initialization
    
    public init(_ dbWriter: any DatabaseWriter) throws {
        self.dbWriter = dbWriter
        try migrator.migrate(dbWriter)
    }
    
    /// Provides a singleton instance configured for local storage.
    public static func shared() throws -> AppDatabase {
        let url = AppStoragePaths.databaseURL
        let dbQueue = try DatabaseQueue(path: url.path)
        return try AppDatabase(dbQueue)
    }
    
    // MARK: - Migration
    
    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        
        #if DEBUG
        migrator.eraseDatabaseOnSchemaChange = true
        #endif

        // Capture all AppConstants strings as plain locals before entering the
        // Sendable GRDB migration closure — the closure is nonisolated and Swift 6
        // rejects direct access to static properties through the @MainActor-inferred
        // AppConstants namespace from inside it.
        let migrationName   = AppConstants.Database.Migrations.createJournal
        let journalTable    = AppConstants.Database.journalTable
        let tagTable        = AppConstants.Database.tagTable
        let entryTagTable   = AppConstants.Database.entryTagTable
        let colId           = AppConstants.Database.Columns.id
        let colText         = AppConstants.Database.Columns.text
        let colTimestamp    = AppConstants.Database.Columns.timestamp
        let colTradingDay   = AppConstants.Database.Columns.tradingDay
        let colImagePath    = AppConstants.Database.Columns.imagePath
        let colType         = AppConstants.Database.Columns.type
        let colLastUsed     = AppConstants.Database.Columns.lastUsed
        let colEntryId      = AppConstants.Database.Columns.entryId
        let colTagId        = AppConstants.Database.Columns.tagId

        migrator.registerMigration(migrationName) { db in
            try db.create(table: journalTable) { t in
                t.column(colId, .text).primaryKey()
                t.column(colText, .text).notNull()
                t.column(colTimestamp, .datetime).notNull().indexed()
                t.column(colTradingDay, .datetime).notNull().indexed()
                t.column(colImagePath, .text)
            }

            try db.create(table: tagTable) { t in
                t.column(colId, .text).primaryKey()
                t.column(colType, .text).notNull()
                t.column(colLastUsed, .datetime).notNull()
            }

            try db.create(table: entryTagTable) { t in
                t.column(colEntryId, .text).notNull().references(journalTable, onDelete: .cascade)
                t.column(colTagId, .text).notNull().references(tagTable, onDelete: .cascade)
                t.primaryKey([colEntryId, colTagId])
            }
        }
        
        return migrator
    }
}
