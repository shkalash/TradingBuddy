import Foundation
import Observation

@Observable
public final class AppRouter {
    public var selection: NavigationSelection?
    
    public init(selection: NavigationSelection? = nil) {
        self.selection = selection
    }
}
