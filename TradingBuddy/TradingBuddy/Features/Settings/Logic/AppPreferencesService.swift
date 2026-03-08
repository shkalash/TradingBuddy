import Foundation
import Observation

/// The production implementation of `PreferencesService` using isolated `UserDefaults`.
///
/// **Responsibilities:**
/// - Managing the persistence of user-facing application settings.
/// - Providing isolated storage for debug and unit testing environments.
/// - Tracking transient session states like `snoozedUntil`.
@Observable
public class AppPreferencesService: PreferencesService {
    // MARK: - Properties
    
    @ObservationIgnored
    private let persistence: PersistenceHandling
    
    // Transient UI State (Not persisted)
    public var viewedTag: String? = nil
    public var searchText: String = ""
    public var activeTradingDay: Date = Date()
    
    // MARK: - Initialization
    
    init(persistence: PersistenceHandling) {
        self.persistence = persistence
    }
    
    // MARK: - Preferences
    
    public var showHistoryJumpWarning: Bool {
        get { 
            access(keyPath: \.showHistoryJumpWarning)
            return persistence.load(for: .showHistoryJumpWarning) ?? true 
        }
        set { 
            withMutation(keyPath: \.showHistoryJumpWarning) {
                persistence.save(value: newValue, for: .showHistoryJumpWarning)
            }
        }
    }
    
    public var rolloverPromptDelayHours: Int {
        get { 
            access(keyPath: \.rolloverPromptDelayHours)
            return persistence.load(for: .rolloverPromptDelayHours) ?? 2 
        }
        set { 
            withMutation(keyPath: \.rolloverPromptDelayHours) {
                persistence.save(value: newValue, for: .rolloverPromptDelayHours)
            }
        }
    }
    
    public var snoozedUntil: Date? {
        get { 
            access(keyPath: \.snoozedUntil)
            return persistence.load(for: .snoozedUntil) 
        }
        set { 
            withMutation(keyPath: \.snoozedUntil) {
                persistence.save(value: newValue, for: .snoozedUntil)
            }
        }
    }
    
    // MARK: - QOL Settings
    
    public var chatFontSize: Double {
        get { 
            access(keyPath: \.chatFontSize)
            let val = persistence.load(for: .chatFontSize) ?? 14.0
            return val > 0 ? val : 14.0
        }
        set { 
            withMutation(keyPath: \.chatFontSize) {
                persistence.save(value: newValue, for: .chatFontSize)
            }
        }
    }
    
    public var isClipboardMonitoringEnabled: Bool {
        get {
            access(keyPath: \.isClipboardMonitoringEnabled)
            return persistence.load(for: .isClipboardMonitoringEnabled) ?? true
        }
        set {
            withMutation(keyPath: \.isClipboardMonitoringEnabled) {
                persistence.save(value: newValue, for: .isClipboardMonitoringEnabled)
            }
        }
    }
    
    public var forceFocusChatOnImageIntake: Bool {
        get {
            access(keyPath: \.forceFocusChatOnImageIntake)
            return persistence.load(for: .forceFocusChatOnImageIntake) ?? true
        }
        set {
            withMutation(keyPath: \.forceFocusChatOnImageIntake) {
                persistence.save(value: newValue, for: .forceFocusChatOnImageIntake)
            }
        }
    }
}
