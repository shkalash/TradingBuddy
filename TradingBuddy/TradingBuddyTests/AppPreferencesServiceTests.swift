import Testing
import Foundation
@testable import TradingBuddy

struct AppPreferencesServiceTests {
    
    private var testDefaults: UserDefaults {
        UserDefaults(suiteName: "io.shkalash.TradingBuddy.unit-tests")!
    }
    
    init() {
        // Wipe tests defaults before each test
        testDefaults.removePersistentDomain(forName: "io.shkalash.TradingBuddy.unit-tests")
    }
    
    @Test("Default values are correct")
    func testDefaultValues() {
        let service = AppPreferencesService(defaults: testDefaults)
        
        #expect(service.showHistoryJumpWarning == true)
        #expect(service.rolloverPromptDelayHours == 2)
        #expect(service.snoozedUntil == nil)
    }
    
    @Test("Updating preferences persists correctly")
    func testPreferenceUpdates() {
        let service = AppPreferencesService(defaults: testDefaults)
        
        service.showHistoryJumpWarning = false
        service.rolloverPromptDelayHours = 5
        
        let futureDate = Date().addingTimeInterval(3600)
        service.snoozedUntil = futureDate
        
        // Create a new instance to verify persistence in UserDefaults
        let newService = AppPreferencesService(defaults: testDefaults)
        
        #expect(newService.showHistoryJumpWarning == false)
        #expect(newService.rolloverPromptDelayHours == 5)
        
        if let retrievedDate = newService.snoozedUntil {
            #expect(abs(retrievedDate.timeIntervalSince(futureDate)) < 0.1)
        } else {
            Issue.record("snoozedUntil should not be nil")
        }
    }
}
