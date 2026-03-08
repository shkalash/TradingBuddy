import Foundation

/// The production implementation of `PreferencesService` using isolated `UserDefaults`.
///
/// **Responsibilities:**
/// - Managing the persistence of user-facing application settings.
/// - Providing isolated storage for debug and unit testing environments.
/// - Tracking transient session states like `snoozedUntil`.
public class AppPreferencesService: PreferencesService {
    // MARK: - Properties
    
    private let defaults: UserDefaults
    
    // MARK: - Initialization
    
    public init(defaults: UserDefaults = .init(suiteName: AppStoragePaths.userDefaultsSuiteName) ?? .standard) {
        self.defaults = defaults
    }
    
    // MARK: - Preferences
    
    public var showHistoryJumpWarning: Bool {
        get { defaults.object(forKey: AppConstants.Storage.showHistoryJumpWarningKey) as? Bool ?? true }
        set { defaults.set(newValue, forKey: AppConstants.Storage.showHistoryJumpWarningKey) }
    }
    
    public var rolloverPromptDelayHours: Int {
        get { defaults.object(forKey: AppConstants.Storage.rolloverPromptDelayHoursKey) as? Int ?? 2 }
        set { defaults.set(newValue, forKey: AppConstants.Storage.rolloverPromptDelayHoursKey) }
    }
    
    public var snoozedUntil: Date? {
        get { defaults.object(forKey: AppConstants.Storage.snoozedUntilKey) as? Date }
        set { defaults.set(newValue, forKey: AppConstants.Storage.snoozedUntilKey) }
    }
    
    // MARK: - QOL Settings
    
    public var chatFontSize: Double {
        get { 
            let val = defaults.double(forKey: AppConstants.Storage.chatFontSizeKey)
            return val > 0 ? val : 14.0 // Default 14
        }
        set { defaults.set(newValue, forKey: AppConstants.Storage.chatFontSizeKey) }
    }
}
