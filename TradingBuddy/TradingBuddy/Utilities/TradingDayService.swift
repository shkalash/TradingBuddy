//
//  TradingDayCalculator.swift
//  TradingBuddy
//
//  Created by Shai Kalev on 3/6/26.
//


import Foundation

public protocol TradingDayCalculator {
    func getTradingDay(for date: Date) -> Date
}

public struct ChicagoTradingDayService: TradingDayCalculator {
    private let chicagoTimeZone = TimeZone(identifier: "America/Chicago")!
    
    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = chicagoTimeZone
        return cal
    }

    public init() {}

    public func getTradingDay(for date: Date) -> Date {
        let cal = calendar
        let hour = cal.component(.hour, from: date)

        // 1. Rollover Logic: If it's 6 PM (18:00) or later, it belongs to the next calendar day
        var tradingDate = date
        if hour >= 18 {
            tradingDate = cal.date(byAdding: .day, value: 1, to: tradingDate)!
        }

        // 2. Weekend Logic
        // In Gregorian calendar: Sunday = 1, Monday = 2, ..., Friday = 6, Saturday = 7
        let weekday = cal.component(.weekday, from: tradingDate)

        if weekday == 7 { 
            // Result is Saturday -> Snap back to Friday
            tradingDate = cal.date(byAdding: .day, value: -1, to: tradingDate)!
        } else if weekday == 1 { 
            // Result is Sunday -> Snap back to Friday
            tradingDate = cal.date(byAdding: .day, value: -2, to: tradingDate)!
        }

        // 3. Strip the time to return the pure "Day" (00:00:00 Chicago time)
        let components = cal.dateComponents([.year, .month, .day], from: tradingDate)
        return cal.date(from: components)!
    }
}