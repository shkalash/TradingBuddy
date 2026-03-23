//
//  TradingDayServiceTests.swift
//  TradingBuddy
//
//  Created by Shai Kalev on 3/6/26.
//


import Testing
import Foundation
@testable import TradingBuddy // Make sure this matches your exact project name!

struct TradingDayServiceTests {
    let service = ChicagoTradingDayService()
    let chicagoTimeZone = TimeZone(identifier: "America/Chicago")!

    // Helper to quickly create exact Chicago dates for testing
    func createChicagoDate(year: Int = 2026, month: Int, day: Int, hour: Int, minute: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.timeZone = chicagoTimeZone
        return Calendar(identifier: .gregorian).date(from: components)!
    }

    // Helper to verify the correct trading day was returned
    func verify(actual: Date, expectedMonth: Int, expectedDay: Int) {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = chicagoTimeZone
        let month = cal.component(.month, from: actual)
        let day = cal.component(.day, from: actual)
        
        #expect(month == expectedMonth)
        #expect(day == expectedDay)
    }

    @Test("Exact rollover boundary: 5:00 PM CT rolls to next day")
    func testExactRolloverBoundary() {
        // hour >= 17 means 17:00:00 is already the next session
        let input = createChicagoDate(month: 3, day: 5, hour: 17, minute: 0) // Thursday 5:00 PM exactly
        let result = service.getTradingDay(for: input)
        verify(actual: result, expectedMonth: 3, expectedDay: 6) // Friday
    }

    @Test("One minute before rollover stays on the same day")
    func testJustBeforeRollover() {
        let input = createChicagoDate(month: 3, day: 5, hour: 16, minute: 59) // Thursday 4:59 PM
        let result = service.getTradingDay(for: input)
        verify(actual: result, expectedMonth: 3, expectedDay: 5) // Thursday
    }

    @Test("DST (summer, CDT): rollover still fires at 5 PM Chicago time")
    func testRolloverDuringDST() {
        // June is CDT (UTC-5) — rollover is still 5 PM Chicago local, not 6 PM ET
        let input = createChicagoDate(year: 2026, month: 6, day: 10, hour: 17, minute: 0) // Wednesday 5:00 PM CDT
        let result = service.getTradingDay(for: input)
        verify(actual: result, expectedMonth: 6, expectedDay: 11) // Thursday
    }

    @Test("DST (summer, CDT): mid-afternoon stays on same day")
    func testMidDayDuringDST() {
        let input = createChicagoDate(year: 2026, month: 6, day: 10, hour: 14, minute: 0) // Wednesday 2:00 PM CDT
        let result = service.getTradingDay(for: input)
        verify(actual: result, expectedMonth: 6, expectedDay: 10) // Wednesday
    }

    @Test("Standard mid-day trading falls on the same calendar day")
    func testMidDay() {
        let input = createChicagoDate(month: 3, day: 5, hour: 14, minute: 0) // Thursday 2:00 PM
        let result = service.getTradingDay(for: input)
        verify(actual: result, expectedMonth: 3, expectedDay: 5) // Thursday
    }

    @Test("Pre-market hours fall on the same calendar day")
    func testPreMarket() {
        let input = createChicagoDate(month: 3, day: 5, hour: 4, minute: 0) // Thursday 4:00 AM
        let result = service.getTradingDay(for: input)
        verify(actual: result, expectedMonth: 3, expectedDay: 5) // Thursday
    }

    @Test("After 6 PM rolls over to the next trading day")
    func testRollover() {
        let input = createChicagoDate(month: 3, day: 5, hour: 18, minute: 5) // Thursday 6:05 PM
        let result = service.getTradingDay(for: input)
        verify(actual: result, expectedMonth: 3, expectedDay: 6) // Friday
    }

    @Test("Weekend gap: Friday post-market snaps back to Friday")
    func testFridayEvening() {
        let input = createChicagoDate(month: 3, day: 6, hour: 19, minute: 0) // Friday 7:00 PM
        let result = service.getTradingDay(for: input)
        verify(actual: result, expectedMonth: 3, expectedDay: 6) // Friday
    }

    @Test("Weekend gap: Saturday mid-day snaps back to Friday")
    func testSaturday() {
        let input = createChicagoDate(month: 3, day: 7, hour: 12, minute: 0) // Saturday 12:00 PM
        let result = service.getTradingDay(for: input)
        verify(actual: result, expectedMonth: 3, expectedDay: 6) // Friday
    }

    @Test("Weekend gap: Sunday morning snaps back to Friday")
    func testSundayMorning() {
        let input = createChicagoDate(month: 3, day: 8, hour: 10, minute: 0) // Sunday 10:00 AM
        let result = service.getTradingDay(for: input)
        verify(actual: result, expectedMonth: 3, expectedDay: 6) // Friday
    }

    @Test("Sunday evening opens the Monday trading session")
    func testSundayEvening() {
        let input = createChicagoDate(month: 3, day: 8, hour: 18, minute: 0) // Sunday 6:00 PM
        let result = service.getTradingDay(for: input)
        verify(actual: result, expectedMonth: 3, expectedDay: 9) // Monday
    }
}