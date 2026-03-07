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
        
        migrator.registerMigration("createJournal") { db in
            try db.create(table: "journalEntry") { t in
                t.column("id", .text).primaryKey()
                t.column("text", .text).notNull()
                t.column("timestamp", .datetime).notNull().indexed()
                t.column("tradingDay", .datetime).notNull().indexed()
                t.column("imagePath", .text)
            }
            
            try db.create(table: "tag") { t in
                t.column("id", .text).primaryKey() // The tag string itself
                t.column("type", .text).notNull()
                t.column("lastUsed", .datetime).notNull()
            }
            
            try db.create(table: "entryTag") { t in
                t.column("entryId", .text).notNull().references("journalEntry", onDelete: .cascade)
                t.column("tagId", .text).notNull().references("tag", onDelete: .cascade)
                t.primaryKey(["entryId", "tagId"])
            }
        }
        
        return migrator
    }
}
