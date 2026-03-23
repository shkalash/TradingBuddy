import Testing
import SwiftUI
import Foundation
@testable import TradingBuddy

struct TagColorServiceTests {

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

        // Verify a second service instance reading the same persistence sees the saved value
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
