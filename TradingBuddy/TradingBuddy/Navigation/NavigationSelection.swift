import Foundation

/// Defines the available navigation destinations within the application.
///
/// **Responsibilities:**
/// - Representing a selection of a specific trading day.
/// - Representing a selection of a specific tag filter.
/// - Providing a `Hashable` implementation for use in SwiftUI `List` and `NavigationStack`.
public enum NavigationSelection: Hashable {
    case day(Date)
    case tag(String)
}
