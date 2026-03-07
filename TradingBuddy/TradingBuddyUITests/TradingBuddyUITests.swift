//
//  TradingBuddyUITests.swift
//  TradingBuddy
//
//  Created by Shai Kalev on 3/6/26.
//


import XCTest

final class TradingBuddyUITests: XCTestCase {

    override func setUpWithError() throws {
        // Stop immediately when a failure occurs.
        continueAfterFailure = false
    }

    func testAppLaunchesSuccessfully() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Simply assert that the app made it to the foreground without crashing
        XCTAssertTrue(app.state == .runningForeground, "The app should launch successfully.")
    }
}