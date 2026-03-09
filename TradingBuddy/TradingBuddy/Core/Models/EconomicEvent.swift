import Foundation

/// Represents a single economic event from a financial calendar.
public struct EconomicEvent: Codable, Identifiable, Hashable, Sendable {
    public let id: String
    public let date: Date
    public let event: String
    public let country: String
    public let impact: String?
    public let actual: String?
    public let previous: String?
    public let estimate: String?
    public let unit: String?
    
    public init(id: String = UUID().uuidString, date: Date, event: String, country: String, impact: String?, actual: String?, previous: String?, estimate: String?, unit: String?) {
        self.id = id
        self.date = date
        self.event = event
        self.country = country
        self.impact = impact
        self.actual = actual
        self.previous = previous
        self.estimate = estimate
        self.unit = unit
    }
}
