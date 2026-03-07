import SwiftUI
import Observation

// If your TagType isn't a String enum, this gracefully falls back to describing it
@Observable
public class TagColorService {
    private let defaults = UserDefaults.standard
    private let colorsKey = "tagCategoryColors"
    
    // Keys will be "future", "ticker", "topic"
    public var colorMap: [String: String] = [:] {
        didSet {
            if let encoded = try? JSONEncoder().encode(colorMap) {
                defaults.set(encoded, forKey: colorsKey)
            }
        }
    }
    
    public init() {
        if let data = defaults.data(forKey: colorsKey),
           let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
            self.colorMap = decoded
        }
    }
    
    public func getColor(for type: TagType) -> Color {
        let key = String(describing: type).lowercased()
        if let hex = colorMap[key], let color = Color(hex: hex) {
            return color
        }
        
        // Beautiful defaults if the user hasn't set anything
        switch type {
        case .future: return .blue
        case .ticker: return .green
        case .topic: return .purple
        }
    }
    
    public func setColor(_ color: Color, for type: TagType) {
        let key = String(describing: type).lowercased()
        colorMap[key] = color.toHex()
    }
}

// MARK: - Color Hex Extensions
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        self.init(
            red: Double((rgb & 0xFF0000) >> 16) / 255.0,
            green: Double((rgb & 0x00FF00) >> 8) / 255.0,
            blue: Double(rgb & 0x0000FF) / 255.0
        )
    }
    
    func toHex() -> String? {
        guard let nsColor = NSColor(self).usingColorSpace(.sRGB) else { return nil }
        let red = Int(round(nsColor.redComponent * 255))
        let green = Int(round(nsColor.greenComponent * 255))
        let blue = Int(round(nsColor.blueComponent * 255))
        return String(format: "#%02X%02X%02X", red, green, blue)
    }
}
