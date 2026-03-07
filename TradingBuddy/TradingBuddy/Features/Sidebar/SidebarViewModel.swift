import Foundation
import Observation

/// A model representing a year in the trading history sidebar.
public struct HistoryYear: Identifiable {
    public let id: Int
    public let months: [HistoryMonth]
    
    public init(id: Int, months: [HistoryMonth]) {
        self.id = id
        self.months = months
    }
}

/// A model representing a month in the trading history sidebar.
public struct HistoryMonth: Identifiable {
    public let id: String
    public let title: String
    public let days: [Date]
    
    public init(id: String, title: String, days: [Date]) {
        self.id = id
        self.title = title
        self.days = days
    }
}

/// Processes and prepares trading history data for display in the Sidebar.
///
/// **Responsibilities:**
/// - Fetching raw trading days and tags from the repository.
/// - Building a hierarchical tree structure (Year -> Month -> Days) for historical navigation.
/// - Filtering tags by category for organized display.
/// - Responding to database updates to maintain synchronized state.
@Observable
public final class SidebarViewModel {
    // MARK: - Properties
    
    private let repository: JournalRepository
    
    public var currentMonthDays: [Date] = []
    public var currentMonthTitle: String = ""
    public var historyYears: [HistoryYear] = []
    
    public var futureTags: [Tag] = []
    public var tickerTags: [Tag] = []
    public var topicTags: [Tag] = []
    
    // MARK: - Initialization
    
    public init(repository: JournalRepository) {
        self.repository = repository
    }
    
    // MARK: - Data Fetching
    
    @MainActor
    public func fetchData() async {
        let rawDays = (try? await repository.allTradingDays()) ?? []
        buildTree(from: rawDays)
        
        let tags = (try? await repository.allTags()) ?? []
        futureTags = tags.filter { $0.type == .future }
        tickerTags = tags.filter { $0.type == .ticker }
        topicTags = tags.filter { $0.type == .topic }
    }
    
    // MARK: - Processing Logic
    
    private func buildTree(from days: [Date]) {
        let calendar = Calendar.current
        let today = Date()
        let currentYear = calendar.component(.year, from: today)
        let currentMonth = calendar.component(.month, from: today)
        
        var currentDays: [Date] = []
        var historyDict: [Int: [Int: [Date]]] = [:]
        
        for day in days {
            let y = calendar.component(.year, from: day)
            let m = calendar.component(.month, from: day)
            
            if y == currentYear && m == currentMonth {
                currentDays.append(day)
            } else {
                historyDict[y, default: [:]][m, default: []].append(day)
            }
        }
        
        self.currentMonthDays = currentDays.sorted(by: >)
        
        let monthName = calendar.monthSymbols[currentMonth - 1]
        self.currentMonthTitle = String(localized: "sidebar.current_month.title \(monthName)", comment: "Title for current month section in sidebar")
        
        var histYears: [HistoryYear] = []
        for year in historyDict.keys.sorted(by: >) {
            var histMonths: [HistoryMonth] = []
            let monthsDict = historyDict[year]!
            for month in monthsDict.keys.sorted(by: >) {
                let sortedDays = monthsDict[month]!.sorted(by: >)
                let title = calendar.monthSymbols[month - 1]
                histMonths.append(HistoryMonth(id: "\(year)-\(month)", title: title, days: sortedDays))
            }
            histYears.append(HistoryYear(id: year, months: histMonths))
        }
        self.historyYears = histYears
    }
}
