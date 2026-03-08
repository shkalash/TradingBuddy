import Foundation

/// An abstraction for managing application-wide user preferences.
///
/// **Responsibilities:**
/// - Storing and retrieving UI-related settings (e.g., historical day warnings).
/// - Managing the snooze duration for session rollover prompts.
/// - Providing an interface for persisting transient state like `snoozedUntil`.
/// - Managing QOL settings like font size and split positions.
public protocol PreferencesService: AnyObject {
    var showHistoryJumpWarning: Bool { get set }
    var rolloverPromptDelayHours: Int { get set }
    var snoozedUntil: Date? { get set }
    
    // QOL Settings
    var chatFontSize: Double { get set }
}
