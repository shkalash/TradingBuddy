import Testing
import Foundation
@testable import TradingBuddy

struct AppPreferencesServiceTests {

    @Test("Default values are correct")
    func testDefaultValues() {
        let persistence = MockPersistenceHandler()
        let service = AppPreferencesService(persistence: persistence)

        #expect(service.showHistoryJumpWarning == true)
        #expect(service.rolloverPromptDelayHours == 2)
        #expect(service.snoozedUntil == nil)
    }

    @Test("Updating preferences persists correctly")
    func testPreferenceUpdates() {
        let persistence = MockPersistenceHandler()
        let service = AppPreferencesService(persistence: persistence)

        service.showHistoryJumpWarning = false
        service.rolloverPromptDelayHours = 5

        let futureDate = Date().addingTimeInterval(3600)
        service.snoozedUntil = futureDate

        #expect(service.showHistoryJumpWarning == false)
        #expect(service.rolloverPromptDelayHours == 5)
        #expect(service.snoozedUntil == futureDate)
    }
}
