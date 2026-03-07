import Foundation
import AppKit

public protocol ImageStorageService {
    func saveImage(_ image: NSImage, date: Date) async throws -> String
    func getFileURL(for relativePath: String) -> URL
    func clearAllImages() throws
    func getBaseDirectory() -> URL
}

public class LocalImageStorageService: ImageStorageService {
    private var imagesDirectory: URL {
        AppStoragePaths.imagesDirectory
    }
    
    public init() {
        try? FileManager.default.createDirectory(at: self.imagesDirectory, withIntermediateDirectories: true)
    }
    
    public func saveImage(_ image: NSImage, date: Date) async throws -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateFolderName = formatter.string(from: date)
        
        let dateFolderURL = imagesDirectory.appendingPathComponent(dateFolderName, isDirectory: true)
        try? FileManager.default.createDirectory(at: dateFolderURL, withIntermediateDirectories: true)
        
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
        
        return "\(dateFolderName)/\(fileName)"
    }
    
    public func getFileURL(for relativePath: String) -> URL {
        return imagesDirectory.appendingPathComponent(relativePath)
    }
    
    public func clearAllImages() throws {
        try FileManager.default.removeItem(at: imagesDirectory)
        try FileManager.default.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
    }
    
    public func getBaseDirectory() -> URL {
        return AppStoragePaths.baseDirectory
    }
}
