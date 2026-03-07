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
        get { defaults.object(forKey: "showHistoryJumpWarning") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "showHistoryJumpWarning") }
    }
    
    public var rolloverPromptDelayHours: Int {
        get { defaults.object(forKey: "rolloverPromptDelayHours") as? Int ?? 2 }
        set { defaults.set(newValue, forKey: "rolloverPromptDelayHours") }
    }
    
    public var snoozedUntil: Date? {
        get { defaults.object(forKey: "snoozedUntil") as? Date }
        set { defaults.set(newValue, forKey: "snoozedUntil") }
    }
}
