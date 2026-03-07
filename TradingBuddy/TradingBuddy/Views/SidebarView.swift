import SwiftUI

struct SidebarView: View {
    @Environment(AppRouter.self) private var router
    @Environment(ChatViewModel.self) private var chatViewModel // We need this to watch for new entries
    @Environment(TagColorService.self) private var colorService
    @State private var sidebarViewModel: SidebarViewModel
    
    init(repository: JournalRepository) {
        _sidebarViewModel = State(initialValue: SidebarViewModel(repository: repository))
    }
    
    var body: some View {
        @Bindable var bindableRouter = router
        
        // Bind directly to the router selection
        List(selection: $bindableRouter.selection) {
            
            // SECTION 1: TRADING DAYS
            ForEach(sidebarViewModel.groupedDays, id: \.month) { group in
                Section(group.month) {
                    ForEach(group.days, id: \.self) { day in
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.accentColor)
                            Text(day, format: .dateTime.weekday(.wide).day())
                        }
                        // Use .tag instead of NavigationLink for macOS SplitView
                        .tag(NavigationSelection.day(day))
                    }
                }
            }
            
            // SECTION 2: FUTURES
            if !sidebarViewModel.futureTags.isEmpty {
                Section("Futures") {
                    ForEach(sidebarViewModel.futureTags, id: \.id) { tag in
                        Label(tag.id, systemImage: "chart.line.uptrend.xyaxis")
                            .foregroundColor(colorService.getColor(for: .future))
                            .tag(NavigationSelection.tag(tag.id))
                    }
                }
            }
            
            // SECTION 3: TOPICS
            if !sidebarViewModel.topicTags.isEmpty {
                Section("Topics") {
                    ForEach(sidebarViewModel.topicTags, id: \.id) { tag in
                        Label(tag.id, systemImage: "number")
                            .foregroundColor(colorService.getColor(for: .topic))
                            .tag(NavigationSelection.tag(tag.id))
                    }
                }
            }
            
            // SECTION 4: TICKERS
            if !sidebarViewModel.tickerTags.isEmpty {
                Section("Tickers") {
                    ForEach(sidebarViewModel.tickerTags, id: \.id) { tag in
                        Label(tag.id, systemImage: "building.columns.fill")
                            .foregroundColor(colorService.getColor(for: .ticker))
                            .tag(NavigationSelection.tag(tag.id))
                    }
                }
            }
            
            
        }
        .navigationTitle("History")
        .task {
            // Load data when sidebar first appears
            await sidebarViewModel.fetchData()
        }
        // ONLY refresh the sidebar if we actually saved a new message or tag!
        .onChange(of: chatViewModel.entries.count) { _, _ in
            Task {
                await sidebarViewModel.fetchData()
            }
        }
    }
}
