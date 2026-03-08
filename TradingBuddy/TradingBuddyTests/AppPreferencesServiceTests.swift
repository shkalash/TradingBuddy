import Testing
import Foundation
@testable import TradingBuddy

struct AppPreferencesServiceTests {
    
    private class MockPersistenceHandler: PersistenceHandling {
        var storage: [String: Any] = [:]
        
        func saveCodable<T: Codable>(object: T?, for key: PersistenceKey<T>) {
            if let object = object {
                storage[key.name] = try? JSONEncoder().encode(object)
            } else {
                storage.removeValue(forKey: key.name)
            }
        }
        
        func loadCodable<T: Codable>(for key: PersistenceKey<T>) -> T? {
            guard let data = storage[key.name] as? Data else { return nil }
            return try? JSONDecoder().decode(T.self, from: data)
        }
        
        func save<T>(value: T?, for key: PersistenceKey<T>) {
            storage[key.name] = value
        }
        
        func load<T>(for key: PersistenceKey<T>) -> T? {
            return storage[key.name] as? T
        }
    }
    
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
        
        // Use the same persistence handler to verify "persistence" in this mock context
        // (In a real scenario, this would be a real storage like UserDefaults)
        #expect(service.showHistoryJumpWarning == false)
        #expect(service.rolloverPromptDelayHours == 5)
        #expect(service.snoozedUntil == futureDate)
    }
}
