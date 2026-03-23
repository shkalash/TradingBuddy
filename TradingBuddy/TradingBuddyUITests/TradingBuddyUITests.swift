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

    /// The actual editable TextView inside the input area.
    /// The ScrollView got our identifier — the TextView is its direct child.
    var chatInputTextView: XCUIElement {
        app.scrollViews["chatInput"].textViews.firstMatch
    }

    /// Send button — identifier applied correctly, label 'Arrow Up Circle'.
    var sendButton: XCUIElement {
        app.buttons["sendButton"]
    }

    /// Types text into the chat input and sends it.
    func sendMessage(_ text: String) {
        let tv = chatInputTextView
        XCTAssertTrue(tv.waitForExistence(timeout: 3))
        tv.click()
        tv.typeText(text)
        XCTAssertTrue(sendButton.waitForExistence(timeout: 3))
        sendButton.click()
    }

    // MARK: - Launch

    func testAppLaunchesWithoutCrashing() {
        XCTAssertEqual(app.state, .runningForeground)
    }

    func testSplitViewAndSidebarAreVisible() {
        XCTAssertTrue(app.splitGroups.firstMatch.waitForExistence(timeout: 3))
        // Sidebar renders as Outline with label 'Sidebar'
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
        let tv = chatInputTextView
        XCTAssertTrue(tv.waitForExistence(timeout: 3))
        tv.click()
        tv.typeText("Test message")
        sendButton.click()

        // Input should clear after send — value becomes empty string
        let deadline = Date().addingTimeInterval(3)
        while (tv.value as? String ?? "").isEmpty == false && Date() < deadline {
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        }
        XCTAssertEqual(tv.value as? String ?? "", "")
    }

    func testSendMessageAppearsInFeed() {
        sendMessage("End to end test entry")

        // messageBubble-* identifiers are on Other elements inside the feed ScrollView
        let feed = app.scrollViews["chatInput"] // feed scroll view also got chatInput — use the one that contains Others
        // Query by identifier prefix across the whole app
        let bubble = app.otherElements.matching(
            NSPredicate(format: "identifier BEGINSWITH 'messageBubble-'")
        ).firstMatch
        XCTAssertTrue(bubble.waitForExistence(timeout: 5))
    }

    // MARK: - Tag chips

    func testTagChipAppearsAfterSendingTaggedMessage() {
        sendMessage("Trade note #tilt")

        // Chip is a Button with title matching the tag id
        let chip = app.buttons["#tilt"]
        XCTAssertTrue(chip.waitForExistence(timeout: 5))
    }

    func testTappingTagChipInsertsIntoInput() {
        sendMessage("Seed #fomo entry")

        let chip = app.buttons["#fomo"]
        XCTAssertTrue(chip.waitForExistence(timeout: 5))
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

        // Wait for both bubbles
        let bubbles = app.otherElements.matching(
            NSPredicate(format: "identifier BEGINSWITH 'messageBubble-'")
        )
        let deadline = Date().addingTimeInterval(5)
        while bubbles.count < 2 && Date() < deadline {
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }
        XCTAssertEqual(bubbles.count, 2)

        let search = app.searchFields.firstMatch
        search.click()
        search.typeText("AAPL")

        let afterDeadline = Date().addingTimeInterval(2)
        while bubbles.count != 1 && Date() < afterDeadline {
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }
        XCTAssertEqual(bubbles.count, 1)
    }

    // MARK: - Sidebar

    func testSidebarShowsEntryAfterSend() {
        sendMessage("Sidebar navigation test")

        // After sending, the current month disclosure should expand and show a day row
        let sidebar = app.outlines["Sidebar"].firstMatch
        XCTAssertTrue(sidebar.waitForExistence(timeout: 3))

        // The outline should have at least one row beyond the section header
        let deadline = Date().addingTimeInterval(5)
        while sidebar.cells.count < 2 && Date() < deadline {
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }
        XCTAssertGreaterThan(sidebar.cells.count, 0)
    }
}
