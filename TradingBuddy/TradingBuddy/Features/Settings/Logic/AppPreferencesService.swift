import Foundation

/// The production implementation of `PreferencesService` using isolated `UserDefaults`.
///
/// **Responsibilities:**
/// - Managing the persistence of user-facing application settings.
/// - Providing isolated storage for debug and unit testing environments.
/// - Tracking transient session states like `snoozedUntil`.
public class AppPreferencesService: PreferencesService {
    // MARK: - Properties
    
    private let persistence: PersistenceHandling
    
    // MARK: - Initialization
    
    init(persistence: PersistenceHandling) {
        self.persistence = persistence
    }
    
    // MARK: - Preferences
    
    public var showHistoryJumpWarning: Bool {
        get { persistence.load(for: .showHistoryJumpWarning) ?? true }
        set { persistence.save(value: newValue, for: .showHistoryJumpWarning) }
    }
    
    public var rolloverPromptDelayHours: Int {
        get { persistence.load(for: .rolloverPromptDelayHours) ?? 2 }
        set { persistence.save(value: newValue, for: .rolloverPromptDelayHours) }
    }
    
    public var snoozedUntil: Date? {
        get { persistence.load(for: .snoozedUntil) }
        set { persistence.save(value: newValue, for: .snoozedUntil) }
    }
    
    // MARK: - QOL Settings
    
    public var chatFontSize: Double {
        get { 
            let val = persistence.load(for: .chatFontSize) ?? 14.0
            return val > 0 ? val : 14.0
        }
        set { persistence.save(value: newValue, for: .chatFontSize) }
    }
}
