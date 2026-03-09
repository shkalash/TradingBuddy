import Foundation
import SwiftUI

/// A protocol defining all major services and dependencies in the application.
///
/// This acts as the "Composition Root" of the app, allowing different implementations
/// for production, previews, and unit testing.
@MainActor
protocol AppDependencies {
    // Handlers & Services
    var persistenceHandler: PersistenceHandling { get }
    var preferencesService: PreferencesService { get }
    var repository: JournalRepository { get }
    var imageStorage: ImageStorageService { get }
    
    // Utilities
    var timeProvider: TimeProvider { get }
    var dayCalculator: TradingDayCalculator { get }
    var messageParser: MessageParser { get }
    var newsService: EconomicNewsServicing { get }
    
    // Navigation & State
    var router: AppRouter { get }
    var colorService: TagColorService { get }
    var session: AppSession { get }
    var commands: AppCommands { get }
    var pasteboardMonitor: PasteboardMonitorProviding { get }
}
