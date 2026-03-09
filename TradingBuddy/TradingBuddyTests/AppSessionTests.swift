import XCTest
@testable import TradingBuddy

@MainActor
final class AppSessionTests: XCTestCase {
    
    var session: AppSession!
    var mockNewsService: MockNewsService!
    var mockPrefs: PreviewMocks.MockPreferences!
    var timeProvider: MutableTimeProvider!
    var dayCalculator: TradingDayCalculator!
    
    override func setUp() {
        super.setUp()
        mockNewsService = MockNewsService()
        mockPrefs = PreviewMocks.MockPreferences()
        timeProvider = MutableTimeProvider(now: Date())
        dayCalculator = ChicagoTradingDayService()
        
        session = AppSession(
            dayCalculator: dayCalculator,
            timeProvider: timeProvider,
            newsService: mockNewsService,
            preferences: mockPrefs
        )
    }
    
    func testInitialShowMorningBriefing() async {
        // Setup mock news for today
        let today = dayCalculator.getTradingDay(for: timeProvider.now)
        mockNewsService.stubbedEvents = [
            EconomicEvent(date: today.addingTimeInterval(3600), event: "Test Event", country: "US", impact: "High", actual: nil, previous: nil, estimate: nil, unit: nil)
        ]
        
        session.forceRefreshNews()
        
        // Trigger update (wait for monitor loop)
        try? await Task.sleep(nanoseconds: 1_100_000_000)
        
        XCTAssertTrue(session.showMorningBriefing)
        XCTAssertFalse(session.todaysEvents.isEmpty)
    }
    
    func testDismissMorningBriefing() async {
        session.showMorningBriefing = true
        let today = session.activeTradingDay
        
        session.dismissMorningBriefing()
        
        XCTAssertFalse(session.showMorningBriefing)
        XCTAssertEqual(mockPrefs.lastNewsBriefingShownDate, today)
    }
    
    func testSnoozeMorningBriefing() async {
        session.showMorningBriefing = true
        
        session.snoozeMorningBriefing()
        
        XCTAssertFalse(session.showMorningBriefing)
        XCTAssertNil(mockPrefs.lastNewsBriefingShownDate)
    }
    
    func testDoesNotShowTwiceOnSameDayAfterDismiss() async {
        let today = dayCalculator.getTradingDay(for: timeProvider.now)
        mockNewsService.stubbedEvents = [
            EconomicEvent(date: today.addingTimeInterval(3600), event: "Test Event", country: "US", impact: "High", actual: nil, previous: nil, estimate: nil, unit: nil)
        ]
        mockPrefs.lastNewsBriefingShownDate = today
        
        session.forceRefreshNews()
        
        // Wait for monitor
        try? await Task.sleep(nanoseconds: 1_100_000_000)
        
        XCTAssertFalse(session.showMorningBriefing, "Should not show if already dismissed for today")
    }
    
    func testSessionRolloverShowsBriefingAgain() async {
        // 1. Setup today (dismissed)
        let monday = Date.from(year: 2026, month: 3, day: 9, hour: 10) // Monday morning
        timeProvider.now = monday
        let mondayTradingDay = dayCalculator.getTradingDay(for: monday)
        
        mockNewsService.stubbedEvents = [
            EconomicEvent(date: monday.addingTimeInterval(3600), event: "Monday Event", country: "US", impact: "High", actual: nil, previous: nil, estimate: nil, unit: nil)
        ]
        mockPrefs.lastNewsBriefingShownDate = mondayTradingDay
        
        session.forceRefreshNews()
        
        // Wait for first cycle
        try? await Task.sleep(nanoseconds: 1_100_000_000)
        XCTAssertFalse(session.showMorningBriefing)
        
        // 2. Rollover to Tuesday session (Monday 5pm CT)
        let mondayEvening = Date.from(year: 2026, month: 3, day: 9, hour: 18) // 6pm ET / 5pm CT
        timeProvider.now = mondayEvening
        let tuesdayTradingDay = dayCalculator.getTradingDay(for: mondayEvening)
        
        mockNewsService.stubbedEvents = [
            EconomicEvent(date: mondayEvening.addingTimeInterval(3600), event: "Tuesday Event", country: "US", impact: "High", actual: nil, previous: nil, estimate: nil, unit: nil)
        ]
        
        // Wait for monitor
        try? await Task.sleep(nanoseconds: 1_100_000_000)
        
        XCTAssertTrue(session.showMorningBriefing, "Should show again after session rollover")
        XCTAssertEqual(session.activeTradingDay, tuesdayTradingDay)
    }
    
    func testImpendingNewsBannerTrigger() async {
        let now = timeProvider.now
        let eventTime = now.addingTimeInterval(600) // 10 minutes away
        
        session.todaysEvents = [
            EconomicEvent(date: eventTime, event: "Impending News", country: "US", impact: "High", actual: nil, previous: nil, estimate: nil, unit: nil)
        ]
        
        // Wait for monitor
        try? await Task.sleep(nanoseconds: 1_100_000_000)
        
        XCTAssertNotNil(session.nextImpendingEvent)
        XCTAssertEqual(session.nextImpendingEvent?.event, "Impending News")
    }
}

// MARK: - Helper Mocks for Tests

class MockNewsService: EconomicNewsServicing {
    var stubbedEvents: [EconomicEvent] = []
    
    func fetchEconomicEvents(from startDate: Date, to endDate: Date) async throws -> [EconomicEvent] {
        return stubbedEvents
    }
}

extension Date {
    static func from(year: Int, month: Int, day: Int, hour: Int = 0, minute: Int = 0) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.timeZone = TimeZone(identifier: "America/New_York")
        return Calendar.current.date(from: components)!
    }
}
