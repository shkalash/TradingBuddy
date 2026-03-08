import Foundation
import SwiftUI

/// A centralized layer for executing high-level application commands.
///
/// **Responsibilities:**
/// - Providing a single entry point for complex actions (e.g., database reset, rollover handling).
/// - Orchestrating updates across multiple services (Preferences, Router, Repository).
@MainActor
public final class AppCommands {
    // MARK: - Dependencies
    
    private let preferences: PreferencesService
    private let router: AppRouter
    private let repository: JournalRepository
    private let imageStorage: ImageStorageService
    
    // MARK: - Initialization
    
    init(
        preferences: PreferencesService,
        router: AppRouter,
        repository: JournalRepository,
        imageStorage: ImageStorageService
    ) {
        self.preferences = preferences
        self.router = router
        self.repository = repository
        self.imageStorage = imageStorage
    }
    
    // MARK: - Font Scaling
    
    public func increaseFontSize() {
        preferences.chatFontSize += 1
    }
    
    public func decreaseFontSize() {
        preferences.chatFontSize = max(8, preferences.chatFontSize - 1)
    }
    
    // MARK: - Data Actions
    
    public func resetDatabase(includingImages: Bool) async {
        do {
            if includingImages {
                try await repository.clearDatabaseAndImages()
                try? imageStorage.clearAllImages()
            } else {
                try await repository.clearDatabaseOnly()
            }
            // Signal views to reload
            NotificationCenter.default.post(name: AppConstants.Notifications.databaseCleared, object: nil)
        } catch {
            print("AppCommands: Failed to reset database: \(error)")
        }
    }
}
