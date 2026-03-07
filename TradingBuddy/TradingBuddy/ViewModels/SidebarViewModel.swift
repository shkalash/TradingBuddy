//
//  SidebarViewModel.swift
//  TradingBuddy
//
//  Created by Shai Kalev on 3/6/26.
//


import Foundation
import Observation

@Observable
public final class SidebarViewModel {
    private let repository: JournalRepository
    
    // Grouped by Month/Year string (e.g., "March 2026" -> [Date, Date])
    public var groupedDays: [(month: String, days: [Date])] = []
    
    // Grouped Tags
    public var futureTags: [Tag] = []
    public var tickerTags: [Tag] = []
    public var topicTags: [Tag] = []
    
    public init(repository: JournalRepository) {
        self.repository = repository
    }
    
    @MainActor
    public func fetchData() async {
        do {
            // 1. Fetch and group dates
            let allDays = try await repository.allTradingDays()
            self.groupedDays = groupDatesByMonth(allDays)
            
            // 2. Fetch and group tags
            let allTags = try await repository.allTags()
            self.futureTags = allTags.filter { $0.type == .future }
            self.tickerTags = allTags.filter { $0.type == .ticker }
            self.topicTags = allTags.filter { $0.type == .topic }
            
        } catch {
            print("Sidebar fetch failed: \(error)")
        }
    }
    
    private func groupDatesByMonth(_ dates: [Date]) -> [(String, [Date])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        
        let grouped = Dictionary(grouping: dates) { date in
            formatter.string(from: date)
        }
        
        // Sort months descending (newest month first)
        let sortedMonths = grouped.keys.sorted { string1, string2 in
            guard let d1 = formatter.date(from: string1), let d2 = formatter.date(from: string2) else { return false }
            return d1 > d2
        }
        
        return sortedMonths.map { month in
            // Days are already sorted descending from the DB query
            (month, grouped[month] ?? [])
        }
    }
}
