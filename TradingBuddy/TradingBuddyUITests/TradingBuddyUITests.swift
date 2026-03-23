import XCTest

final class TradingBuddyUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        // In-memory DB: fresh empty state every run, no prod data contamination
        app.launchArguments = ["-UITesting"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Launch

    func testAppLaunchesWithoutCrashing() {
        XCTAssertEqual(app.state, .runningForeground)
    }

    func testSidebarAndChatAreVisible() {
        // NavigationSplitView should render both columns on launch
        XCTAssertTrue(app.splitGroups.firstMatch.exists)
        XCTAssertTrue(app.otherElements["chatView"].waitForExistence(timeout: 3))
    }

    // MARK: - Send a message

    func testSendMessageAppearsInFeed() throws {
        let input = app.textViews["chatInput"]
        XCTAssertTrue(input.waitForExistence(timeout: 3))

        input.click()
        input.typeText("Testing end-to-end send")

        let sendButton = app.buttons["sendButton"]
        XCTAssertTrue(sendButton.isEnabled)
        sendButton.click()

        // After send, input should clear
        XCTAssertEqual(input.value as? String, "")

        // At least one message bubble should now exist in the feed
        let bubble = app.otherElements.matching(NSPredicate(format: "identifier BEGINSWITH 'messageBubble-'")).firstMatch
        XCTAssertTrue(bubble.waitForExistence(timeout: 3))
    }

    func testSendButtonDisabledWhenInputEmpty() {
        let sendButton = app.buttons["sendButton"]
        XCTAssertTrue(sendButton.waitForExistence(timeout: 3))
        XCTAssertFalse(sendButton.isEnabled)
    }

    // MARK: - Tag chips

    func testTagChipAppearsAfterSendingTaggedMessage() throws {
        let input = app.textViews["chatInput"]
        XCTAssertTrue(input.waitForExistence(timeout: 3))

        input.click()
        input.typeText("Trade note #tilt")
        app.buttons["sendButton"].click()

        // The #tilt chip should appear in the suggestion row
        let chip = app.buttons["#tilt"]
        XCTAssertTrue(chip.waitForExistence(timeout: 3))
    }

    func testTappingTagChipInsertsItIntoInput() throws {
        let input = app.textViews["chatInput"]
        XCTAssertTrue(input.waitForExistence(timeout: 3))

        // Seed a tag first
        input.click()
        input.typeText("Seeding #fomo")
        app.buttons["sendButton"].click()

        let chip = app.buttons["#fomo"]
        XCTAssertTrue(chip.waitForExistence(timeout: 3))
        chip.click()

        // Input should now contain the tag
        let inputValue = input.value as? String ?? ""
        XCTAssertTrue(inputValue.contains("#fomo"), "Expected input to contain '#fomo', got: \(inputValue)")
    }

    // MARK: - Search

    func testSearchFilterShowsOnlyMatchingMessages() throws {
        let input = app.textViews["chatInput"]
        XCTAssertTrue(input.waitForExistence(timeout: 3))

        // Send two distinct messages
        input.click()
        input.typeText("Long /ES at open")
        app.buttons["sendButton"].click()

        input.click()
        input.typeText("Watching $AAPL earnings")
        app.buttons["sendButton"].click()

        // Wait for both bubbles
        let bubbles = app.otherElements.matching(NSPredicate(format: "identifier BEGINSWITH 'messageBubble-'"))
        let deadline = Date().addingTimeInterval(3)
        while bubbles.count < 2 && Date() < deadline { RunLoop.current.run(until: Date().addingTimeInterval(0.1)) }
        XCTAssertEqual(bubbles.count, 2)

        // Activate search
        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 3))
        searchField.click()
        searchField.typeText("AAPL")

        // Only one bubble should remain visible
        XCTAssertEqual(bubbles.count, 1)
    }

    // MARK: - Sidebar navigation

    func testSidebarShowsTodayEntry() throws {
        // Send a message so today appears in the sidebar
        let input = app.textViews["chatInput"]
        XCTAssertTrue(input.waitForExistence(timeout: 3))
        input.click()
        input.typeText("Sidebar test entry")
        app.buttons["sendButton"].click()

        // The sidebar list should contain at least one date row
        let sidebarList = app.lists.firstMatch
        XCTAssertTrue(sidebarList.waitForExistence(timeout: 3))
        XCTAssertGreaterThan(sidebarList.cells.count, 0)
    }
}
