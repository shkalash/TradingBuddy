import Foundation
import Combine

/// A container for the application's major services and dependencies.
///
/// **Responsibilities:**
/// - Initializing and holding singletons for persistence, repository, and other core services.
/// - Providing a central point for dependency injection.
class DependencyContainer: ObservableObject {
    // MARK: - Handlers
    
    let persistenceHandler: PersistenceHandling
    let preferencesService: PreferencesService
    
    // MARK: - Initialization
    
    init() {
        let persistence = UserDefaultsPersistenceHandler()
        self.persistenceHandler = persistence
        self.preferencesService = AppPreferencesService(persistence: persistence)
    }
}
