import SwiftUI

struct HistoryYear: Identifiable {
    let id: Int
    let months: [HistoryMonth]
}

struct HistoryMonth: Identifiable {
    let id: String
    let title: String
    let days: [Date]
}

struct SidebarView: View {
    let repository: JournalRepository
    
    @Environment(AppRouter.self) private var router
    @Environment(TagColorService.self) private var colorService
    
    @State private var currentMonthDays: [Date] = []
    @State private var currentMonthTitle: String = ""
    @State private var historyYears: [HistoryYear] = []
    
    @State private var futureTags: [Tag] = []
    @State private var tickerTags: [Tag] = []
    @State private var topicTags: [Tag] = []
    
    @State private var isCurrentMonthExpanded = true
    @State private var isHistoryExpanded = false
    @State private var expandedYears: [Int: Bool] = [:]
    @State private var expandedMonths: [String: Bool] = [:]
    
    var body: some View {
        @Bindable var bindableRouter = router
        
        // Use the native macOS Vertical Split View!
        VSplitView {
            // TOP PANEL
            List(selection: $bindableRouter.selection) {
                Section("Trading Days") {
                    if !currentMonthDays.isEmpty {
                        DisclosureGroup(isExpanded: $isCurrentMonthExpanded) {
                            ForEach(currentMonthDays, id: \.self) { day in
                                NavigationLink(value: NavigationSelection.day(day)) {
                                    Label(day.formatted(.dateTime.weekday(.abbreviated).day()), systemImage: "calendar")
                                }
                            }
                        } label: {
                            ClickableDisclosureLabel(title: currentMonthTitle, isExpanded: $isCurrentMonthExpanded)
                        }
                    }
                    
                    if !historyYears.isEmpty {
                        DisclosureGroup(isExpanded: $isHistoryExpanded) {
                            ForEach(historyYears) { year in
                                let yearBinding = Binding(
                                    get: { expandedYears[year.id, default: false] },
                                    set: { expandedYears[year.id] = $0 }
                                )
                                DisclosureGroup(isExpanded: yearBinding) {
                                    ForEach(year.months) { month in
                                        let monthBinding = Binding(
                                            get: { expandedMonths[month.id, default: false] },
                                            set: { expandedMonths[month.id] = $0 }
                                        )
                                        DisclosureGroup(isExpanded: monthBinding) {
                                            ForEach(month.days, id: \.self) { day in
                                                NavigationLink(value: NavigationSelection.day(day)) {
                                                    Label(day.formatted(.dateTime.weekday(.abbreviated).day()), systemImage: "calendar")
                                                }
                                            }
                                        } label: {
                                            ClickableDisclosureLabel(title: month.title, isExpanded: monthBinding)
                                        }
                                    }
                                } label: {
                                    ClickableDisclosureLabel(title: String(year.id), isExpanded: yearBinding)
                                }
                            }
                        } label: {
                            ClickableDisclosureLabel(title: "History", isExpanded: $isHistoryExpanded)
                        }
                    }
                }
            }
            .listStyle(.sidebar)
            .frame(minHeight: 150) // Prevent squashing the top list
            
            // BOTTOM PANEL
            List(selection: $bindableRouter.selection) {
                TagSidebarSection(title: "Futures", tags: futureTags, icon: "chart.line.uptrend.xyaxis", color: colorService.getColor(for: .future))
                TagSidebarSection(title: "Tickers", tags: tickerTags, icon: "building.columns.fill", color: colorService.getColor(for: .ticker))
                TagSidebarSection(title: "Topics", tags: topicTags, icon: "number", color: colorService.getColor(for: .topic))
            }
            .listStyle(.sidebar)
            .frame(minHeight: 100) // Prevent squashing the bottom list
        }
        .task {
            await fetchData()
        }
        .onReceive(NotificationCenter.default.publisher(for: .databaseCleared)) { _ in
            Task {
                await fetchData()
                if currentMonthDays.isEmpty && historyYears.isEmpty {
                    router.selection = .day(Date())
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .databaseUpdated)) { _ in
            Task {
                await fetchData()
            }
        }
    }
    
    // MARK: - Data Processing
    private func fetchData() async {
        let rawDays = (try? await repository.allTradingDays()) ?? []
        buildTree(from: rawDays)
        
        let tags = (try? await repository.allTags()) ?? []
        futureTags = tags.filter { $0.type == .future }
        tickerTags = tags.filter { $0.type == .ticker }
        topicTags = tags.filter { $0.type == .topic }
    }
    
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
        self.currentMonthTitle = "Current Month (\(calendar.monthSymbols[currentMonth - 1]))"
        
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
