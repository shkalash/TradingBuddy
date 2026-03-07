import Testing
import Foundation
@testable import TradingBuddy

struct AppPreferencesServiceTests {
    
    // Use a unique suite name for each test run to ensure absolute isolation
    private func makeTestDefaults() -> UserDefaults {
        let name = "io.shkalash.TradingBuddy.tests.\(UUID().uuidString)"
        return UserDefaults(suiteName: name)!
    }
    
    @Test("Default values are correct")
    func testDefaultValues() {
        let defaults = makeTestDefaults()
        let service = AppPreferencesService(defaults: defaults)
        
        #expect(service.showHistoryJumpWarning == true)
        #expect(service.rolloverPromptDelayHours == 2)
        #expect(service.snoozedUntil == nil)
    }
    
    @Test("Updating preferences persists correctly")
    func testPreferenceUpdates() {
        let defaults = makeTestDefaults()
        let service = AppPreferencesService(defaults: defaults)
        
        service.showHistoryJumpWarning = false
        service.rolloverPromptDelayHours = 5
        
        let futureDate = Date().addingTimeInterval(3600)
        service.snoozedUntil = futureDate
        
        // Re-initialize with same defaults to verify persistence
        let newService = AppPreferencesService(defaults: defaults)
        
        #expect(newService.showHistoryJumpWarning == false)
        #expect(newService.rolloverPromptDelayHours == 5)
        
        if let retrievedDate = newService.snoozedUntil {
            #expect(abs(retrievedDate.timeIntervalSince(futureDate)) < 0.1)
        } else {
            Issue.record("snoozedUntil should not be nil")
        }
    }
}
