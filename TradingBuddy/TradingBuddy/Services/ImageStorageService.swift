import Foundation
import AppKit

public protocol ImageStorageService {
    func saveImage(_ image: NSImage, date: Date) async throws -> String
    func getFileURL(for relativePath: String) -> URL
    func clearAllImages() throws
    func getBaseDirectory() -> URL
}

public class LocalImageStorageService: ImageStorageService {
    private let imagesDirectory: URL
    
    public init() {
        let appSupportURL = try! FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        self.imagesDirectory = appSupportURL.appendingPathComponent("TradingBuddy/Images", isDirectory: true)
        try? FileManager.default.createDirectory(at: self.imagesDirectory, withIntermediateDirectories: true)
    }
    
    public func saveImage(_ image: NSImage, date: Date) async throws -> String {
        // 1. Create a subfolder for the specific trading day
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateFolderName = formatter.string(from: date)
        
        let dateFolderURL = imagesDirectory.appendingPathComponent(dateFolderName, isDirectory: true)
        try? FileManager.default.createDirectory(at: dateFolderURL, withIntermediateDirectories: true)
        
        // 2. Save the image
        let fileName = UUID().uuidString + ".png"
        let fileURL = dateFolderURL.appendingPathComponent(fileName)
        
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw NSError(domain: "ImageError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to read image pixels"])
        }
        
        let bitmapImage = NSBitmapImageRep(cgImage: cgImage)
        guard let pngData = bitmapImage.representation(using: .png, properties: [:]) else {
            throw NSError(domain: "ImageError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to convert to PNG"])
        }
        
        try pngData.write(to: fileURL)
        
        // 3. Return the relative path (e.g., "2026-03-06/uuid.png") so the DB can find it easily
        return "\(dateFolderName)/\(fileName)"
    }
    
    public func getFileURL(for relativePath: String) -> URL {
        return imagesDirectory.appendingPathComponent(relativePath)
    }
    
    public func clearAllImages() throws {
        // Delete the Images folder entirely, then immediately recreate it empty
        try FileManager.default.removeItem(at: imagesDirectory)
        try FileManager.default.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
    }
    
    public func getBaseDirectory() -> URL {
        // We will return the main "TradingBuddy" folder so the user can see everything
        return imagesDirectory.deletingLastPathComponent()
    }
}
