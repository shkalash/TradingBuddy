import Foundation
import GRDB

/// Categorizes financial identifiers into specific trading instrument types or topics.
///
/// **Responsibilities:**
/// - Providing a standardized set of categories for tag parsing and UI colorization.
/// - Supporting string-based persistence for database storage.
public enum TagType: String, Codable, CaseIterable {
    case future
    case ticker
    case topic
}
