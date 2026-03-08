import Foundation

/// Centralized storage for internal, non-user-facing constants.
public enum AppConstants: Sendable {
    
    /// Database table and column names.
    public enum Database: Sendable {
        public static let journalTable = "journalEntry"
        public static let tagTable = "tag"
        public static let entryTagTable = "entryTag"
        
        public enum Columns: Sendable {
            public static let id = "id"
            public static let text = "text"
            public static let timestamp = "timestamp"
            public static let tradingDay = "tradingDay"
            public static let imagePath = "imagePath"
            public static let type = "type"
            public static let lastUsed = "lastUsed"
            public static let entryId = "entryId"
            public static let tagId = "tagId"
        }
        
        public enum Migrations: Sendable {
            public static let createJournal = "createJournal"
        }
    }
    
    /// Notification name constants for system-wide communication.
    public enum Notifications: Sendable {
        public static let databaseUpdated = Notification.Name("io.shkalash.TradingBuddy.databaseUpdated")
        public static let databaseCleared = Notification.Name("io.shkalash.TradingBuddy.databaseCleared")
    }
    
    /// Keys used for persistence in isolated `UserDefaults` or Database.
    public enum Storage: Sendable {
        public static let userDefaultsSuitePrefix = "io.shkalash.TradingBuddy"
        public static let tagCategoryColorsKey = "tagCategoryColors"
        public static let showHistoryJumpWarningKey = "showHistoryJumpWarning"
        public static let rolloverPromptDelayHoursKey = "rolloverPromptDelayHours"
        public static let snoozedUntilKey = "snoozedUntil"
        
        // QOL Persistence Keys
        public static let chatFontSizeKey = "chatFontSize"
       
        
        public static let debugFolder = "TradingBuddy-Debug"
        public static let productionFolder = "TradingBuddy"
        public static let databaseFileName = "journal.sqlite"
        public static let imagesFolderName = "Images"
    }
    
    /// Regex patterns for parsing trading identifiers.
    public enum Patterns: Sendable {
        public static let future = "(?<!\\S)/[A-Za-z0-9]+"
        public static let ticker = "(?<!\\S)\\$[A-Za-z]+"
        public static let topic = "(?<!\\S)#[A-Za-z0-9_]+"
    }
    
    /// Formatting constants.
    public enum Formats: Sendable {
        public static let imageDateFolder = "yyyy-MM-dd"
        public static let imageExtension = ".png"
    }
    
    /// Error related constants.
    public enum Errors: Sendable {
        public static let imageDomain = "ImageError"
    }
    
    /// Debug related constants.
    public enum Debug: Sendable {
        public static let sampleTags = ["/ES", "/NQ", "$AAPL", "$SPY", "#tilt", "#fomo", "#review", "#strategy", "#patience"]
        public static let sampleTextFormat = "Debug trade note %d for %@: Watched %@ closely. Felt a bit of %@."
    }
}
