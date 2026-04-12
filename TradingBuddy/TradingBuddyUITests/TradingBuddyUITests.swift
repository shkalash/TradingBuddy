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

    var tagChipRow: XCUIElement {
        app.scrollViews["tagChipRow"]
    }

    /// Message text StaticTexts — exactly one per message with text content.
    var messageBubbles: XCUIElementQuery {
        app.scrollViews["messageFeed"].staticTexts.matching(
            NSPredicate(format: "identifier BEGINSWITH 'messageBubble-'")
        )
    }

    /// Types into the chat input, clicks send, and waits for the input to clear
    /// so callers know the full async save round-trip completed.
    func sendMessage(_ text: String) {
        let tv = chatInputTextView
        XCTAssertTrue(tv.waitForExistence(timeout: 3))
        tv.click()
        tv.typeText(text)
        XCTAssertTrue(sendButton.waitForExistence(timeout: 3))
        sendButton.click()
        let deadline = Date().addingTimeInterval(5)
        while (tv.value as? String ?? "").isEmpty == false && Date() < deadline {
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        }
    }

    /// Polls until query.count >= target or timeout elapses.
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
        // Wait for the day row to appear under the disclosure group
        let deadline = Date().addingTimeInterval(5)
        while sidebar.cells.count < 2 && Date() < deadline {
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }
        XCTAssertGreaterThan(sidebar.cells.count, 0)
    }

    // MARK: - View Modes

    func testToggleRulesAndChat() {
        // Start in Chat mode
        XCTAssertTrue(app.scrollViews["messageFeed"].waitForExistence(timeout: 3))
        
        // Toggle to Rules
        let showRulesButton = app.buttons["showRulesButton"].firstMatch
        XCTAssertTrue(showRulesButton.waitForExistence(timeout: 3))
        showRulesButton.click()
        
        // Verify Rules view is visible
        let scrollView = app.scrollViews["rulesView"]
        XCTAssertTrue(scrollView.waitForExistence(timeout: 3))
        XCTAssertFalse(app.scrollViews["messageFeed"].exists)
        
        // Toggle back to Chat
        let showChatButton = app.buttons["showChatButton"]
        XCTAssertTrue(showChatButton.waitForExistence(timeout: 3))
        showChatButton.click()
        
        // Verify Chat view is visible again
        XCTAssertTrue(app.scrollViews["messageFeed"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.otherElements["rulesView"].exists)
    }
    
    func testRulesEditAndSave() {
        // Navigate to Rules
        let showRulesButton = app.buttons["showRulesButton"].firstMatch
        XCTAssertTrue(showRulesButton.waitForExistence(timeout: 3))
        showRulesButton.click()
        
        // Enter Edit Mode
        let editButton = app.buttons["editRulesButton"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 3))
        editButton.click()
        // Type into Editor
        let editor = app.textViews["rulesEditor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 3))
        editor.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).click()
        editor.typeText("My Trading Rules\n1. Dont tilt\n2. Follow the trend")
        
        // Save
        let saveButton = app.buttons["saveRulesButton"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 3))
        saveButton.click()
        // Verify Content is visible in View mode
        let scrollView = app.scrollViews["rulesView"]
        XCTAssertTrue(scrollView.waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["rulesContent"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.staticTexts["rulesContent"].value as? String, "My Trading Rules\n1. Dont tilt\n2. Follow the trend")
    }
}
