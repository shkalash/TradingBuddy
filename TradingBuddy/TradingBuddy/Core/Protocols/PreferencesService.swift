import Foundation

public protocol PreferencesService {
    var showHistoryJumpWarning: Bool { get set }
    var rolloverPromptDelayHours: Int { get set }
    var snoozedUntil: Date? { get set }
}
