//
//  AppDatabase.swift
//  TradingBuddy
//
//  Created by Shai Kalev on 3/6/26.
//


import Foundation
import GRDB

public final class AppDatabase {
    public let dbWriter: any DatabaseWriter

    public init(_ dbWriter: any DatabaseWriter) throws {
        self.dbWriter = dbWriter
        try migrator.migrate(dbWriter)
    }

    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        
        #if DEBUG
        // Speeds up development: wipes the DB if schema changes instead of crashing.
        migrator.eraseDatabaseOnSchemaChange = true
        #endif

        migrator.registerMigration("v1") { db in
            // 1. Create JournalEntry table
            try db.create(table: "journalEntry") { t in
                t.primaryKey("id", .text)
                t.column("text", .text).notNull()
                t.column("timestamp", .datetime).notNull()
                t.column("tradingDay", .datetime).notNull().indexed()
                t.column("imagePath", .text)
            }

            // 2. Create Tag table
            try db.create(table: "tag") { t in
                t.primaryKey("id", .text) // The ID is the string itself (e.g. "/ES")
                t.column("type", .text).notNull()
                t.column("lastUsed", .datetime).notNull()
            }

            // 3. Create EntryTag join table
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