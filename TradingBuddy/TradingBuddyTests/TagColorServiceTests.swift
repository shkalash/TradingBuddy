import Testing
import SwiftUI
import Foundation
@testable import TradingBuddy

struct TagColorServiceTests {
    
    private class MockPersistenceHandler: PersistenceHandling {
        var storage: [String: Any] = [:]
        
        func saveCodable<T: Codable>(object: T?, for key: PersistenceKey<T>) {
            if let object = object {
                storage[key.name] = object
            } else {
                storage.removeValue(forKey: key.name)
            }
        }
        
        func loadCodable<T: Codable>(for key: PersistenceKey<T>) -> T? {
            return storage[key.name] as? T
        }
        
        func save<T>(value: T?, for key: PersistenceKey<T>) {
            storage[key.name] = value
        }
        
        func load<T>(for key: PersistenceKey<T>) -> T? {
            return storage[key.name] as? T
        }
    }
    
    @Test("Default colors are correct when no preferences are saved")
    func testDefaultColors() {
        let persistence = MockPersistenceHandler()
        let service = TagColorService(persistence: persistence)
        
        #expect(service.getColor(for: .future) == .blue)
        #expect(service.getColor(for: .ticker) == .green)
        #expect(service.getColor(for: .topic) == .purple)
    }
    
    @Test("Setting and getting a color persists correctly")
    func testColorPersistence() {
        let persistence = MockPersistenceHandler()
        let service = TagColorService(persistence: persistence)
        let testColor = Color.orange
        
        service.setColor(testColor, for: .future)
        
        let retrievedColor = service.getColor(for: .future)
        #expect(retrievedColor.toHex() == testColor.toHex())
        
        // Verify cross-instance persistence (using the same mock)
        let newService = TagColorService(persistence: persistence)
        #expect(newService.getColor(for: .future).toHex() == testColor.toHex())
    }
    
    @Test("Hex conversion works correctly")
    func testHexConversion() {
        let redHex = "#FF0000"
        let color = Color(hex: redHex)
        
        #expect(color != nil)
        #expect(color?.toHex() == redHex)
    }
}
