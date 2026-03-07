import Foundation

/// An abstraction for accessing the current time to facilitate deterministic testing.
///
/// **Responsibilities:**
/// - Providing a single point of entry for "now" across the application.
/// - Allowing tests to inject a specific time to verify session rollover and history logic.
public protocol TimeProvider: Sendable {
    var now: Date { get }
}

/// The production implementation of `TimeProvider` using the system clock.
public struct SystemTimeProvider: TimeProvider {
    // MARK: - Initialization
    
    public init() {}
    
    // MARK: - Properties
    
    public var now: Date { Date() }
}
