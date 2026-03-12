import Foundation

/// A service protocol for fetching economic news and calendar events.
public protocol EconomicNewsServicing: Sendable {
    /// Fetches economic events for a specific date range.
    func fetchEconomicEvents(from startDate: Date, to endDate: Date) async throws -> [EconomicEvent]
}

/// A service that fetches economic data from the Financial Modeling Prep (FMP) API.
public final class FMPEconomicNewsService: EconomicNewsServicing {
    
    // MARK: - Properties
    
    private let apiKey: String
    private let session: URLSession
    private let decoder: JSONDecoder
    
    // MARK: - Initialization
    
    public init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
        self.decoder = JSONDecoder()
        
        // FMP dates are usually ISO8601-like, but let's be careful.
        // The API returns dates in "yyyy-MM-dd HH:mm:ss" format.
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "UTC")
        self.decoder.dateDecodingStrategy = .formatted(formatter)
    }
    
    // MARK: - EconomicNewsServicing
    
    public func fetchEconomicEvents(from startDate: Date, to endDate: Date) async throws -> [EconomicEvent] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        let startString = formatter.string(from: startDate)
        let endString = formatter.string(from: endDate)
        
        let urlString = "https://financialmodelingprep.com/stable/economic-calendar?from=\(startString)&to=\(endString)&apikey=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await session.data(from: url)
        let events = try decoder.decode([FMPEvent].self, from: data)
        
        // Filter for: (country == "US" AND impact == "High") OR (event contains "Crude Oil Inventories")
        return events.compactMap { fmpEvent in
            let isHighImpactUS = (fmpEvent.country == "US" && fmpEvent.impact == "High")
            let isCrudeOil = fmpEvent.event.localizedCaseInsensitiveContains("Crude Oil Inventories")
            
            guard isHighImpactUS || isCrudeOil else { return nil }
            
            return EconomicEvent(
                date: fmpEvent.date,
                event: fmpEvent.event,
                country: fmpEvent.country,
                impact: fmpEvent.impact,
                actual: fmpEvent.actual,
                previous: fmpEvent.previous,
                estimate: fmpEvent.estimate,
                unit: fmpEvent.unit
            )
        }
    }
}

// MARK: - Internal FMP Model

private struct FMPEvent: Codable {
    let date: Date
    let event: String
    let country: String
    let impact: String?
    let actual: String?
    let previous: String?
    let estimate: String?
    let unit: String?
}
