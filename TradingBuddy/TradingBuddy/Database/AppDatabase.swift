import Foundation
import GRDB

public final class AppDatabase {
    public let dbWriter: any DatabaseWriter

    public static func shared() throws -> AppDatabase {
        let dbURL = AppStoragePaths.databaseURL
        let dbPool = try DatabasePool(path: dbURL.path)
        return try AppDatabase(dbPool)
    }

    public init(_ dbWriter: any DatabaseWriter) throws {
        self.dbWriter = dbWriter
        try migrator.migrate(dbWriter)
    }

    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        
        #if DEBUG
        migrator.eraseDatabaseOnSchemaChange = true
        #endif

        migrator.registerMigration("v1") { db in
            try db.create(table: "journalEntry") { t in
                t.primaryKey("id", .text)
                t.column("text", .text).notNull()
                t.column("timestamp", .datetime).notNull()
                t.column("tradingDay", .datetime).notNull().indexed()
                t.column("imagePath", .text)
            }

            try db.create(table: "tag") { t in
                t.primaryKey("id", .text)
                t.column("type", .text).notNull()
                t.column("lastUsed", .datetime).notNull()
            }

            try db.create(table: "entryTag") { t in
                t.column("entryId", .text).notNull()
                    .references("journalEntry", onDelete: .cascade)
                t.column("tagId", .text).notNull()
                    .references("tag", onDelete: .cascade)
                t.primaryKey(["entryId", "tagId"])
            }
        }

        return migrator
    }
}
