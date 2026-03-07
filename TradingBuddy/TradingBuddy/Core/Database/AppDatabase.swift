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
        
        migrator.registerMigration(AppConstants.Database.Migrations.createJournal) { db in
            try db.create(table: AppConstants.Database.journalTable) { t in
                t.column(AppConstants.Database.Columns.id, .text).primaryKey()
                t.column(AppConstants.Database.Columns.text, .text).notNull()
                t.column(AppConstants.Database.Columns.timestamp, .datetime).notNull().indexed()
                t.column(AppConstants.Database.Columns.tradingDay, .datetime).notNull().indexed()
                t.column(AppConstants.Database.Columns.imagePath, .text)
            }
            
            try db.create(table: AppConstants.Database.tagTable) { t in
                t.column(AppConstants.Database.Columns.id, .text).primaryKey()
                t.column(AppConstants.Database.Columns.type, .text).notNull()
                t.column(AppConstants.Database.Columns.lastUsed, .datetime).notNull()
            }
            
            try db.create(table: AppConstants.Database.entryTagTable) { t in
                t.column(AppConstants.Database.Columns.entryId, .text).notNull().references(AppConstants.Database.journalTable, onDelete: .cascade)
                t.column(AppConstants.Database.Columns.tagId, .text).notNull().references(AppConstants.Database.tagTable, onDelete: .cascade)
                t.primaryKey([AppConstants.Database.Columns.entryId, AppConstants.Database.Columns.tagId])
            }
        }
        
        return migrator
    }
}
