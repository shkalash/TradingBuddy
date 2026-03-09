import Foundation
import Observation

/// Manages shared transient (non-persisted) state across the application.
///
/// **Responsibilities:**
/// - Providing a centralized source of truth for app-level state that doesn't need to be saved to disk.
@Observable @MainActor
public final class AppSession {
    // MARK: - Dependencies
    
    private let dayCalculator: TradingDayCalculator
    private let timeProvider: TimeProvider
    private let newsService: EconomicNewsServicing
    private let preferences: PreferencesService
    
    // MARK: - State
    
    /// The current trading day as calculated by the system.
    public var activeTradingDay: Date {
        dayCalculator.getTradingDay(for: timeProvider.now)
    }
    
    /// Today's high-impact economic events.
    public var todaysEvents: [EconomicEvent] = []
    
    /// The next upcoming economic event that is within the 15-minute window (or soonest).
    public var nextImpendingEvent: EconomicEvent?
    
    /// Whether to show the morning briefing popup.
    public var showMorningBriefing: Bool = false
    
    /// The time remaining until the next impending event in seconds.
    public var secondsToNextEvent: TimeInterval?
    
    private var lastFetchedTradingDay: Date?
    private var monitorTask: Task<Void, Never>?
    
    // MARK: - Initialization
    
    init(dayCalculator: TradingDayCalculator, 
         timeProvider: TimeProvider, 
         newsService: EconomicNewsServicing,
         preferences: PreferencesService) {
        self.dayCalculator = dayCalculator
        self.timeProvider = timeProvider
        self.newsService = newsService
        self.preferences = preferences
        
        startMonitoring()
    }
    
    // MARK: - Actions
    
    /// Mark the morning briefing as seen for today.
    public func dismissMorningBriefing() {
        showMorningBriefing = false
        preferences.lastNewsBriefingShownDate = activeTradingDay
    }
    
    /// Temporarily hide the morning briefing without marking it as seen for the day.
    public func snoozeMorningBriefing() {
        showMorningBriefing = false
    }
    
    /// Manually trigger the morning briefing popup.
    public func forceShowMorningBriefing() {
        showMorningBriefing = true
    }
    
    /// Clears the last fetched trading day, forcing a refresh on the next monitoring cycle.
    internal func forceRefreshNews() {
        lastFetchedTradingDay = nil
    }
    
    // MARK: - Logic
    
    public func startMonitoring() {
        monitorTask?.cancel()
        monitorTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.updateState()
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }
    
    private func updateState() async {
        let currentTradingDay = activeTradingDay
        
        // 1. Check for session rollover or initial fetch
        if lastFetchedTradingDay != currentTradingDay {
            await fetchTodaysNews(for: currentTradingDay)
            lastFetchedTradingDay = currentTradingDay
            
            // Auto-show only if not already shown for this trading day
            if !todaysEvents.isEmpty {
                let lastShown = preferences.lastNewsBriefingShownDate
                if lastShown == nil || lastShown! < currentTradingDay {
                    showMorningBriefing = true
                }
            }
        }
        
        // 2. Identify next impending event within 15 minutes
        updateNextImpendingEvent()
    }
    
    private func fetchTodaysNews(for tradingDay: Date) async {
        do {
            // Fetch events for today and tomorrow to handle session rollovers and different timezones properly
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: tradingDay)!
            let events = try await newsService.fetchEconomicEvents(from: tradingDay, to: tomorrow)
            
            // Filter events that actually fall into the CURRENT trading session
            // For CME, a trading day "2024-03-11" starts "2024-03-10 17:00:00 CT"
            // But FMP API returns events in UTC.
            // Let's just keep it simple: if the event date's trading day matches, it's today's event.
            self.todaysEvents = events.filter { 
                dayCalculator.getTradingDay(for: $0.date) == tradingDay 
            }.sorted(by: { $0.date < $1.date })
            
        } catch {
            print("AppSession: Failed to fetch news: \(error)")
        }
    }
    
    private func updateNextImpendingEvent() {
        let now = timeProvider.now
        
        // Find the first event that hasn't happened yet
        let upcoming = todaysEvents.filter { $0.date > now }
        
        if let next = upcoming.first {
            let diff = next.date.timeIntervalSince(now)
            
            // Banner triggers when <= 15 minutes (900 seconds) away
            if diff <= 900 {
                self.nextImpendingEvent = next
                self.secondsToNextEvent = diff
            } else {
                self.nextImpendingEvent = nil
                self.secondsToNextEvent = nil
            }
        } else {
            self.nextImpendingEvent = nil
            self.secondsToNextEvent = nil
        }
    }
}
