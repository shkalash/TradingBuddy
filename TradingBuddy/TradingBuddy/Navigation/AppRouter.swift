import Foundation
import Observation

/// Manages the global navigation state of the application.
///
/// **Responsibilities:**
/// - Tracking the currently selected trading day or tag.
/// - Providing a single source of truth for routing logic.
/// - Facilitating deep linking and navigation state restoration.
@Observable
public final class AppRouter {
    // MARK: - Properties
    
    public var selection: NavigationSelection?
    
    // MARK: - Initialization
    
    public init(selection: NavigationSelection? = nil) {
        self.selection = selection
    }
}
