import Foundation
import Observation

/// Manages shared transient (non-persisted) state across the application.
///
/// **Responsibilities:**
/// - Providing a centralized source of truth for app-level state that doesn't need to be saved to disk.
@Observable
public final class AppSession {
    // MARK: - Dependencies
    
    private let dayCalculator: TradingDayCalculator
    private let timeProvider: TimeProvider
    
    // MARK: - State
    
    /// The current trading day as calculated by the system.
    public var activeTradingDay: Date {
        dayCalculator.getTradingDay(for: timeProvider.now)
    }
    
    // MARK: - Initialization
    
    init(dayCalculator: TradingDayCalculator, timeProvider: TimeProvider) {
        self.dayCalculator = dayCalculator
        self.timeProvider = timeProvider
    }
}
