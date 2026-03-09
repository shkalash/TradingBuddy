import SwiftUI
import AppKit

/// The root navigation container for the TradingBuddy application.
///
/// **Responsibilities:**
/// - Orchestrating the primary `NavigationSplitView`.
/// - Managing the global toolbar and debug utilities.
/// - Responding to system-wide database reset events.
struct ContentView: View {
    // MARK: - Properties
    @State private var columnVisibility = NavigationSplitViewVisibility.all

    let dependencies: any AppDependencies

    // MARK: - Body

    var body: some View {
        @Bindable var session = dependencies.session

        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(dependencies: dependencies)
        } detail: {
            ZStack(alignment: .top) {
                ChatView(dependencies: dependencies)

                NewsBannerView(session: session)
                    .zIndex(1)
            }
        }
        .task {
            // Initial load
            dependencies.router.selection = .day(dependencies.session.activeTradingDay)
        }
        .sheet(isPresented: $session.showMorningBriefing) {
            MorningBriefingView(
                events: session.todaysEvents,
                onDismiss: { session.dismissMorningBriefing() },
                onSnooze: { session.snoozeMorningBriefing() }
            )
        }
#if DEBUG
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { dependencies.session.forceShowMorningBriefing() }) {
                    Label("Show News", systemImage: "newspaper")
                }
                .help("Show Morning Economic Briefing")
            }
            
            debugToolbar
        }
#else
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { dependencies.session.forceShowMorningBriefing() }) {
                    Label("Show News", systemImage: "newspaper")
                }
                .help("Show Morning Economic Briefing")
            }
        }
#endif
    }
    
    // MARK: - Subviews
#if DEBUG
    @ToolbarContentBuilder
    private var debugToolbar: some ToolbarContent {

        ToolbarItemGroup(placement: .navigation) {
            Menu {
                Button("Trigger Morning Briefing") {
                    dependencies.session.forceShowMorningBriefing()
                }
                
                Button("Mock Impending News (10m)") {
                    dependencies.session.todaysEvents.append(EconomicEvent(
                        date: Date().addingTimeInterval(600),
                        event: "Debug High Impact Event",
                        country: "US",
                        impact: "High",
                        actual: nil, previous: nil, estimate: nil, unit: nil
                    ))
                }
                
                Button("Clear News Seen State") {
                    dependencies.preferencesService.lastNewsBriefingShownDate = nil
                }
            } label: {
                Label("Debug News", systemImage: "ant")
            }
            
            Button(action: {
                Task {
                    if let repo = dependencies.repository as? GRDBJournalRepository {
                        try? await repo.debugPopulate()
                        NotificationCenter.default.post(name: AppConstants.Notifications.databaseUpdated, object: nil)
                    }
                }
            }) {
                Label("Seed DB", systemImage: "sparkles")
                    .foregroundStyle(.purple)
            }
            .help("Populate DB with random data")
            
            Button(action: {
                Task {
                    await dependencies.commands.resetDatabase(includingImages: true)
                }
            }) {
                Label("Nuke DB", systemImage: "flame.fill")
                    .foregroundStyle(.red)
            }
            .help("Instantly wipe DB and images without asking")
        }

    }
#endif
}

// MARK: - Previews

#Preview {
    let mockDeps = PreviewMocks.MockDependencyContainer()
    return ContentView(dependencies: mockDeps)
}
