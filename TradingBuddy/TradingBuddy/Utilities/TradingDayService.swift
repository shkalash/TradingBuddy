import Foundation

/// Defines the strategy for calculating the active trading day based on real-world time.
public protocol TradingDayCalculator {
    /// Returns the normalized date (00:00:00) representing the trading session for a given point in time.
    func getTradingDay(for date: Date) -> Date
}

/// A specialized calculator for the Chicago/CME trading schedule.
///
/// **Responsibilities:**
/// - Implementing the 5:00 PM CT (6:00 PM ET) rollover logic.
/// - Correcting weekend gaps (Friday evening through Sunday afternoon) to the preceding Friday.
/// - Normalizing timestamps to the start of the trading day for database grouping.
public struct ChicagoTradingDayService: TradingDayCalculator {
    
    // MARK: - Initialization
    
    public init() {}
    
    // MARK: - Logic
    
    public func getTradingDay(for date: Date) -> Date {
        let central = TimeZone(identifier: "America/Chicago")!
        var calendar = Calendar.current
        calendar.timeZone = central
        
        let hour = calendar.component(.hour, from: date)
        var targetDate = date
        
        // Rollover logic: 5:00 PM CT marks the start of the next trading session.
        if hour >= 17 {
            targetDate = calendar.date(byAdding: .day, value: 1, to: date)!
        }
        
        // Weekend Gap logic: Snap Saturday/Sunday back to the Friday session.
        let targetWeekday = calendar.component(.weekday, from: targetDate)
        if targetWeekday == 7 { // Saturday
            targetDate = calendar.date(byAdding: .day, value: -1, to: targetDate)!
        } else if targetWeekday == 1 { // Sunday
            targetDate = calendar.date(byAdding: .day, value: -2, to: targetDate)!
        }
        
        let components = calendar.dateComponents([.year, .month, .day], from: targetDate)
        return calendar.date(from: components)!
    }
}
