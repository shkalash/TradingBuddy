import Testing
import SwiftUI
import Foundation
@testable import TradingBuddy

struct TagColorServiceTests {
    
    private var testDefaults: UserDefaults {
        UserDefaults(suiteName: "io.shkalash.TradingBuddy.unit-tests")!
    }
    
    init() {
        // Wipe tests defaults before each test
        testDefaults.removePersistentDomain(forName: "io.shkalash.TradingBuddy.unit-tests")
    }
    
    @Test("Default colors are correct when no preferences are saved")
    func testDefaultColors() {
        let service = TagColorService(defaults: testDefaults)
        
        #expect(service.getColor(for: .future) == .blue)
        #expect(service.getColor(for: .ticker) == .green)
        #expect(service.getColor(for: .topic) == .purple)
    }
    
    @Test("Setting and getting a color persists correctly")
    func testColorPersistence() {
        let service = TagColorService(defaults: testDefaults)
        let testColor = Color.orange
        
        service.setColor(testColor, for: .future)
        
        let retrievedColor = service.getColor(for: .future)
        #expect(retrievedColor.toHex() == testColor.toHex())
        
        // Verify cross-instance persistence
        let newService = TagColorService(defaults: testDefaults)
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
