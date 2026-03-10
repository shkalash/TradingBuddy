import Foundation

/// Centralized storage for internal, non-user-facing constants.
public enum AppConstants: Sendable {
    
    /// Database table and column names.
    public enum Database: Sendable {
        public nonisolated static let journalTable = "journalEntry"
        public nonisolated static let tagTable = "tag"
        public nonisolated static let entryTagTable = "entryTag"
        
        public enum Columns: Sendable {
            public nonisolated static let id = "id"
            public nonisolated static let text = "text"
            public nonisolated static let timestamp = "timestamp"
            public nonisolated static let tradingDay = "tradingDay"
            public nonisolated static let imagePath = "imagePath"
            public nonisolated static let type = "type"
            public nonisolated static let lastUsed = "lastUsed"
            public nonisolated static let entryId = "entryId"
            public nonisolated static let tagId = "tagId"
        }
        
        public enum Migrations: Sendable {
            public nonisolated static let createJournal = "createJournal"
        }
    }
    
    /// Notification name constants for system-wide communication.
    public enum Notifications: Sendable {
        public nonisolated static let databaseUpdated = Notification.Name("io.shkalash.TradingBuddy.databaseUpdated")
        public nonisolated static let databaseCleared = Notification.Name("io.shkalash.TradingBuddy.databaseCleared")
    }
    
    /// Keys used for persistence in isolated `UserDefaults` or Database.
    public enum Storage: Sendable {
        public nonisolated static let userDefaultsSuitePrefix = "io.shkalash.TradingBuddy"
        public nonisolated static let tagCategoryColorsKey = "tagCategoryColors"
        public nonisolated static let showHistoryJumpWarningKey = "showHistoryJumpWarning"
        public nonisolated static let rolloverPromptDelayHoursKey = "rolloverPromptDelayHours"
        public nonisolated static let snoozedUntilKey = "snoozedUntil"
        
        // QOL Persistence Keys
        public nonisolated static let chatFontSizeKey = "chatFontSize"
        public nonisolated static let windowStatekey = "windowState"
        public nonisolated static let isClipboardMonitoringEnabledKey = "isClipboardMonitoringEnabled"
        public nonisolated static let forceFocusChatOnImageIntakeKey = "forceFocusChatOnImageIntake"
        public nonisolated static let lastMigrationVersionKey = "lastMigrationVersion"
        public nonisolated static let lastNewsBriefingShownDateKey = "lastNewsBriefingShownDate"
        
        public nonisolated static let debugFolder = "TradingBuddy-Debug"
        public nonisolated static let productionFolder = "TradingBuddy"
        public nonisolated static let databaseFileName = "journal.sqlite"
        public nonisolated static let imagesFolderName = "Images"
    }
    
    /// Regex patterns for parsing trading identifiers.
    public enum Patterns: Sendable {
        public nonisolated static let future = "(?<!\\S)/[A-Za-z0-9]+"
        public nonisolated static let ticker = "(?<!\\S)\\$[A-Za-z]+"
        public nonisolated static let topic = "(?<!\\S)#[^ \\.\\,:\\;\\n\\r]+"
    }
    
    /// Formatting constants.
    public enum Formats: Sendable {
        public nonisolated static let imageDateFolder = "yyyy-MM-dd"
        public nonisolated static let imageExtension = ".png"
    }
    
    /// Error related constants.
    public enum Errors: Sendable {
        public nonisolated static let imageDomain = "ImageError"
    }
    
    /// Debug related constants.
    public enum Debug: Sendable {
        public nonisolated static let sampleTags = ["/ES", "/NQ", "$AAPL", "$SPY", "#tilt", "#fomo", "#review", "#strategy", "#patience"]
        public nonisolated static let sampleTextFormat = "Debug trade note %d for %@: Watched %@ closely. Felt a bit of %@."
    }
}
