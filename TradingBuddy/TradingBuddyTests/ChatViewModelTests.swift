import Testing
import Foundation
import AppKit
@testable import TradingBuddy

@MainActor
struct ChatViewModelTests {

    func makeSUT(now: Date) -> (ChatViewModel, MockJournalRepository, MutableTimeProvider, PreviewMocks.MockPreferences, AppRouter) {
        let timeProvider = MutableTimeProvider(now: now)
        let repo = MockJournalRepository(timeProvider: timeProvider, dayCalculator: ChicagoTradingDayService())
        let prefs = PreviewMocks.MockPreferences()
        let router = AppRouter()

        let container = TestDependencyContainer(
            preferencesService: prefs,
            repository: repo,
            timeProvider: timeProvider,
            router: router
        )

        let vm = ChatViewModel(dependencies: container)
        return (vm, repo, timeProvider, prefs, router)
    }

    @Test("Sending a message normally saves and reloads entries")
    func testNormalSend() async throws {
        let tz = TimeZone(identifier: "America/Chicago")!
        let now = Calendar(identifier: .gregorian).date(from: DateComponents(timeZone: tz, year: 2026, month: 3, day: 4, hour: 12))!

        let (vm, repo, _, _, _) = makeSUT(now: now)

        vm.inputText = "Normal trade"
        await vm.sendMessage()

        #expect(repo.mockEntries.count == 1)
        #expect(vm.entries.count == 1)
        #expect(vm.showAlert == false)
    }

    @Test("Sending on a historical day triggers rollover prompt, then saves to today on confirm")
    func testHistoryWarningInterception() async throws {
        let tz = TimeZone(identifier: "America/Chicago")!
        let now = Calendar(identifier: .gregorian).date(from: DateComponents(timeZone: tz, year: 2026, month: 3, day: 4, hour: 12))!
        let yesterday = Calendar(identifier: .gregorian).date(from: DateComponents(timeZone: tz, year: 2026, month: 3, day: 3, hour: 12))!

        let (vm, repo, _, _, router) = makeSUT(now: now)

        await vm.load(day: yesterday)
        router.selection = .day(yesterday)

        vm.inputText = "Forgot to log this"
        await vm.sendMessage()

        // viewedDay != activeTradingDay triggers rolloverPrompt first (not historyWarning)
        #expect(repo.mockEntries.isEmpty)
        #expect(vm.showAlert == true)
        #expect(vm.activeAlert == .rolloverPrompt)

        await vm.handleAlertConfirmation()
        #expect(repo.mockEntries.count == 1)
        #expect(router.selection == .day(vm.activeTradingDay))
    }

    @Test("Rollover triggers if sending after a new day started")
    func testRolloverPrompt() async throws {
        let tz = TimeZone(identifier: "America/Chicago")!
        let monday2PM = Calendar(identifier: .gregorian).date(from: DateComponents(timeZone: tz, year: 2026, month: 3, day: 9, hour: 14))!

        let (vm, _, timeProvider, _, _) = makeSUT(now: monday2PM)

        // Advance clock into Tuesday session (Monday 8 PM CT)
        let monday8PM = Calendar(identifier: .gregorian).date(from: DateComponents(timeZone: tz, year: 2026, month: 3, day: 9, hour: 20))!
        timeProvider.now = monday8PM

        vm.inputText = "Late night note"
        await vm.sendMessage()

        #expect(vm.showAlert == true)
        #expect(vm.activeAlert == .rolloverPrompt)
    }

    @Test("Snoozed user bypasses all alerts and saves immediately")
    func testSnoozedUserSavesWithoutAlert() async throws {
        let tz = TimeZone(identifier: "America/Chicago")!
        // Start on Monday in the Monday session
        let monday2PM = Calendar(identifier: .gregorian).date(from: DateComponents(timeZone: tz, year: 2026, month: 3, day: 9, hour: 14))!

        let (vm, repo, timeProvider, prefs, _) = makeSUT(now: monday2PM)

        // Advance clock into Tuesday session — would normally trigger rolloverPrompt
        let monday8PM = Calendar(identifier: .gregorian).date(from: DateComponents(timeZone: tz, year: 2026, month: 3, day: 9, hour: 20))!
        timeProvider.now = monday8PM

        // Snooze until 3 hours from now
        prefs.snoozedUntil = monday8PM.addingTimeInterval(3 * 3600)

        vm.inputText = "Snoozed note"
        await vm.sendMessage()

        // No alert — should have saved directly
        #expect(vm.showAlert == false)
        #expect(vm.activeAlert == nil)
        #expect(repo.mockEntries.count == 1)
    }

    @Test("Search text correctly filters entries locally")
    func testLocalSearchFiltering() async throws {
        let tz = TimeZone(identifier: "America/Chicago")!
        let now = Calendar(identifier: .gregorian).date(from: DateComponents(timeZone: tz, year: 2026, month: 3, day: 4, hour: 12))!
        let (vm, repo, _, _, _) = makeSUT(now: now)

        _ = try await repo.saveEntry(text: "Bought /ES here", imagePath: nil, date: nil)
        _ = try await repo.saveEntry(text: "Watching $AAPL drop", imagePath: nil, date: nil)

        await vm.load(day: vm.activeTradingDay)
        #expect(vm.entries.count == 2)

        vm.searchText = "AAPL"
        #expect(vm.filteredEntries.count == 1)
        #expect(vm.filteredEntries.first?.text.contains("AAPL") == true)
    }

    @Test("Updating a message updates the DB and reloads the view")
    func testUpdateMessage() async throws {
        let tz = TimeZone(identifier: "America/Chicago")!
        let now = Calendar(identifier: .gregorian).date(from: DateComponents(timeZone: tz, year: 2026, month: 3, day: 4, hour: 12))!
        let (vm, repo, _, _, _) = makeSUT(now: now)

        let entry = try await repo.saveEntry(text: "Original text", imagePath: nil, date: nil)
        await vm.load(day: vm.activeTradingDay)

        await vm.updateMessage(id: entry.id, newText: "Edited text", newImage: nil, imagePath: nil)

        #expect(repo.mockEntries.first?.text == "Edited text")
        #expect(vm.entries.first?.text == "Edited text")
    }

    @Test("appendTagToInput: empty input gets tag + trailing space")
    func testAppendTagToEmptyInput() {
        let tz = TimeZone(identifier: "America/Chicago")!
        let now = Calendar(identifier: .gregorian).date(from: DateComponents(timeZone: tz, year: 2026, month: 3, day: 4, hour: 12))!
        let (vm, _, _, _, _) = makeSUT(now: now)

        let tag = Tag(id: "#tilt", type: .topic, lastUsed: now)
        vm.appendTagToInput(tag)
        #expect(vm.inputText == "#tilt ")
    }

    @Test("appendTagToInput: input with trailing space appends directly")
    func testAppendTagWithTrailingSpace() {
        let tz = TimeZone(identifier: "America/Chicago")!
        let now = Calendar(identifier: .gregorian).date(from: DateComponents(timeZone: tz, year: 2026, month: 3, day: 4, hour: 12))!
        let (vm, _, _, _, _) = makeSUT(now: now)

        let tag = Tag(id: "#tilt", type: .topic, lastUsed: now)
        vm.inputText = "some text "
        vm.appendTagToInput(tag)
        #expect(vm.inputText == "some text #tilt ")
    }

    @Test("appendTagToInput: input without trailing space inserts space before tag")
    func testAppendTagWithoutTrailingSpace() {
        let tz = TimeZone(identifier: "America/Chicago")!
        let now = Calendar(identifier: .gregorian).date(from: DateComponents(timeZone: tz, year: 2026, month: 3, day: 4, hour: 12))!
        let (vm, _, _, _, _) = makeSUT(now: now)

        let tag = Tag(id: "#tilt", type: .topic, lastUsed: now)
        vm.inputText = "some text"
        vm.appendTagToInput(tag)
        #expect(vm.inputText == "some text #tilt ")
    }
}
