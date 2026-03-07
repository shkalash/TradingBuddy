import SwiftUI

/// The primary navigation sidebar for the application.
///
/// **Responsibilities:**
/// - Providing a hierarchical navigation interface for trading days.
/// - Displaying categorized tags for quick filtering.
/// - Syncing with the global `AppRouter` to manage selection state.
struct SidebarView: View {
    // MARK: - Properties
    
    @State private var viewModel: SidebarViewModel
    @Environment(AppRouter.self) private var router
    @Environment(TagColorService.self) private var colorService
    
    @State private var isCurrentMonthExpanded = true
    @State private var isHistoryExpanded = false
    @State private var expandedYears: [Int: Bool] = [:]
    @State private var expandedMonths: [String: Bool] = [:]
    
    // MARK: - Initialization
    
    public init(repository: JournalRepository) {
        self._viewModel = State(initialValue: SidebarViewModel(repository: repository))
    }
    
    // MARK: - Body
    
    var body: some View {
        @Bindable var bindableRouter = router
        
        VSplitView {
            dateSection(selection: $bindableRouter.selection)
            tagSection(selection: $bindableRouter.selection)
        }
        .task { await viewModel.fetchData() }
        .onReceive(NotificationCenter.default.publisher(for: AppConstants.Notifications.databaseCleared)) { _ in
            handleDatabaseClear()
        }
        .onReceive(NotificationCenter.default.publisher(for: AppConstants.Notifications.databaseUpdated)) { _ in
            Task { await viewModel.fetchData() }
        }
    }
    
    // MARK: - Sections
    
    private func dateSection(selection: Binding<NavigationSelection?>) -> some View {
        List(selection: selection) {
            Section(header: Text("sidebar.section.trading_days")) {
                currentMonthDisclosure
                historyDisclosure
            }
        }
        .listStyle(.sidebar)
        .frame(minHeight: 150)
    }
    
    private func tagSection(selection: Binding<NavigationSelection?>) -> some View {
        List(selection: selection) {
            TagSidebarSection(title: String(localized: "sidebar.section.tags.futures"), tags: viewModel.futureTags, icon: "chart.line.uptrend.xyaxis", color: colorService.getColor(for: .future))
            TagSidebarSection(title: String(localized: "sidebar.section.tags.tickers"), tags: viewModel.tickerTags, icon: "building.columns.fill", color: colorService.getColor(for: .ticker))
            TagSidebarSection(title: String(localized: "sidebar.section.tags.topics"), tags: viewModel.topicTags, icon: "number", color: colorService.getColor(for: .topic))
        }
        .listStyle(.sidebar)
        .frame(minHeight: 100)
    }
    
    // MARK: - Disclosures
    
    private var currentMonthDisclosure: some View {
        Group {
            if !viewModel.currentMonthDays.isEmpty {
                DisclosureGroup(isExpanded: $isCurrentMonthExpanded) {
                    ForEach(viewModel.currentMonthDays, id: \.self) { day in
                        NavigationLink(value: NavigationSelection.day(day)) {
                            Label(day.formatted(.dateTime.weekday(.abbreviated).day()), systemImage: "calendar")
                        }
                    }
                } label: {
                    ClickableDisclosureLabel(title: viewModel.currentMonthTitle, isExpanded: $isCurrentMonthExpanded)
                }
            }
        }
    }
    
    private var historyDisclosure: some View {
        Group {
            if !viewModel.historyYears.isEmpty {
                DisclosureGroup(isExpanded: $isHistoryExpanded) {
                    ForEach(viewModel.historyYears) { year in
                        yearDisclosure(for: year)
                    }
                } label: {
                    ClickableDisclosureLabel(title: String(localized: "sidebar.history.label"), isExpanded: $isHistoryExpanded)
                }
            }
        }
    }
    
    private func yearDisclosure(for year: HistoryYear) -> some View {
        let yearBinding = Binding(
            get: { expandedYears[year.id, default: false] },
            set: { expandedYears[year.id] = $0 }
        )
        return DisclosureGroup(isExpanded: yearBinding) {
            ForEach(year.months) { month in
                monthDisclosure(for: month)
            }
        } label: {
            ClickableDisclosureLabel(title: String(year.id), isExpanded: yearBinding)
        }
    }
    
    private func monthDisclosure(for month: HistoryMonth) -> some View {
        let monthBinding = Binding(
            get: { expandedMonths[month.id, default: false] },
            set: { expandedMonths[month.id] = $0 }
        )
        return DisclosureGroup(isExpanded: monthBinding) {
            ForEach(month.days, id: \.self) { day in
                NavigationLink(value: NavigationSelection.day(day)) {
                    Label(day.formatted(.dateTime.weekday(.abbreviated).day()), systemImage: "calendar")
                }
            }
        } label: {
            ClickableDisclosureLabel(title: month.title, isExpanded: monthBinding)
        }
    }
    
    // MARK: - Handlers
    
    private func handleDatabaseClear() {
        Task {
            await viewModel.fetchData()
            if viewModel.currentMonthDays.isEmpty && viewModel.historyYears.isEmpty {
                router.selection = .day(Date())
            }
        }
    }
}

// MARK: - Previews

#Preview {
    SidebarView(repository: PreviewMocks.MockRepo())
        .environment(AppRouter())
        .environment(TagColorService())
}
