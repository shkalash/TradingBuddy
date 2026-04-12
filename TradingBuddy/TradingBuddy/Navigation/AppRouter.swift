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
    // MARK: - Types
    
    public enum AppViewMode: Hashable {
        case chat
        case rules
    }
    
    public enum RulesMode: Hashable {
        case view
        case edit
    }
    
    // MARK: - Properties
    
    public var selection: NavigationSelection?
    public var viewMode: AppViewMode = .chat
    public var rulesMode: RulesMode = .view
    
    // MARK: - Initialization
    
    public init(selection: NavigationSelection? = nil, viewMode: AppViewMode = .chat, rulesMode: RulesMode = .view) {
        self.selection = selection
        self.viewMode = viewMode
        self.rulesMode = rulesMode
    }
}
