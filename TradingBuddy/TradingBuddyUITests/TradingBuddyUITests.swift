import XCTest

final class TradingBuddyUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-UITesting"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Helpers

    /// The actual editable TextView inside the input ScrollView.
    var chatInputTextView: XCUIElement {
        app.scrollViews["chatInput"].textViews.firstMatch
    }

    var sendButton: XCUIElement {
        app.buttons["sendButton"]
    }

    /// The horizontal chip row ScrollView.
    var tagChipRow: XCUIElement {
        app.scrollViews["tagChipRow"]
    }

    /// All rendered message bubbles.
    var messageBubbles: XCUIElementQuery {
        app.otherElements.matching(NSPredicate(format: "identifier BEGINSWITH 'messageBubble-'"))
    }

    /// Types into the chat input and clicks send. Waits for the input to clear
    /// before returning so the caller knows the save round-trip completed.
    func sendMessage(_ text: String, waitForClear: Bool = true) {
        let tv = chatInputTextView
        XCTAssertTrue(tv.waitForExistence(timeout: 3))
        tv.click()
        tv.typeText(text)
        XCTAssertTrue(sendButton.waitForExistence(timeout: 3))
        sendButton.click()
        if waitForClear {
            let deadline = Date().addingTimeInterval(5)
            while (tv.value as? String ?? "").isEmpty == false && Date() < deadline {
                RunLoop.current.run(until: Date().addingTimeInterval(0.05))
            }
        }
    }

    /// Waits until `query.count >= target` or timeout elapses.
    func waitFor(_ query: XCUIElementQuery, count target: Int, timeout: TimeInterval = 5) {
        let deadline = Date().addingTimeInterval(timeout)
        while query.count < target && Date() < deadline {
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }
    }

    // MARK: - Launch

    func testAppLaunchesWithoutCrashing() {
        XCTAssertEqual(app.state, .runningForeground)
    }

    func testSplitViewAndSidebarAreVisible() {
        XCTAssertTrue(app.splitGroups.firstMatch.waitForExistence(timeout: 3))
        XCTAssertTrue(app.outlines["Sidebar"].waitForExistence(timeout: 3))
    }

    func testChatInputAndSendButtonExist() {
        XCTAssertTrue(chatInputTextView.waitForExistence(timeout: 3))
        XCTAssertTrue(sendButton.waitForExistence(timeout: 3))
    }

    // MARK: - Send button state

    func testSendButtonDisabledWhenInputEmpty() {
        XCTAssertTrue(sendButton.waitForExistence(timeout: 3))
        XCTAssertFalse(sendButton.isEnabled)
    }

    func testSendButtonEnabledAfterTyping() {
        let tv = chatInputTextView
        XCTAssertTrue(tv.waitForExistence(timeout: 3))
        tv.click()
        tv.typeText("hello")
        XCTAssertTrue(sendButton.isEnabled)
    }

    // MARK: - Send message

    func testSendMessageClearsInput() {
        sendMessage("Test clear input")
        XCTAssertEqual(chatInputTextView.value as? String ?? "", "")
    }

    func testSendMessageAppearsInFeed() {
        sendMessage("End to end test entry")
        waitFor(messageBubbles, count: 1)
        XCTAssertGreaterThanOrEqual(messageBubbles.count, 1)
    }

    func testSendMultipleMessagesAllAppearInFeed() {
        sendMessage("First entry")
        sendMessage("Second entry")
        waitFor(messageBubbles, count: 2)
        XCTAssertGreaterThanOrEqual(messageBubbles.count, 2)
    }

    // MARK: - Tag chips

    func testTagChipAppearsAfterSendingTaggedMessage() {
        sendMessage("Trade note #tilt")
        XCTAssertTrue(tagChipRow.waitForExistence(timeout: 5))
        XCTAssertTrue(tagChipRow.buttons["#tilt"].waitForExistence(timeout: 3))
    }

    func testTappingTagChipInsertsIntoInput() {
        sendMessage("Seed #fomo entry")
        XCTAssertTrue(tagChipRow.waitForExistence(timeout: 5))

        // Scope to tagChipRow to avoid matching the sidebar button with same label
        let chip = tagChipRow.buttons["#fomo"]
        XCTAssertTrue(chip.waitForExistence(timeout: 3))
        chip.click()

        let value = chatInputTextView.value as? String ?? ""
        XCTAssertTrue(value.contains("#fomo"), "Expected '#fomo' in input, got: \(value)")
    }

    // MARK: - Search

    func testSearchFieldExistsInToolbar() {
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 3))
        XCTAssertEqual(search.placeholderValue, "Search...")
    }

    func testSearchFilterReducesFeedToMatches() {
        sendMessage("Long /ES at open")
        sendMessage("Watching $AAPL earnings")
        waitFor(messageBubbles, count: 2)
        XCTAssertEqual(messageBubbles.count, 2)

        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 3))
        search.click()
        search.typeText("AAPL")

        // Wait for filter to apply
        let deadline = Date().addingTimeInterval(3)
        while messageBubbles.count != 1 && Date() < deadline {
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }
        XCTAssertEqual(messageBubbles.count, 1)
    }

    // MARK: - Sidebar

    func testSidebarShowsEntryAfterSend() {
        sendMessage("Sidebar navigation test")
        let sidebar = app.outlines["Sidebar"].firstMatch
        XCTAssertTrue(sidebar.waitForExistence(timeout: 3))
        waitFor(sidebar.cells, count: 2, timeout: 5) // header cell + at least one day cell
        XCTAssertGreaterThan(sidebar.cells.count, 0)
    }
}
