import Foundation
import AppKit

/// The concrete implementation of `ImageStorageService` for local disk persistence.
///
/// **Responsibilities:**
/// - Managing the creation and cleanup of image directories.
/// - Serializing `NSImage` objects to PNG files on disk.
/// - Providing isolated storage paths for debug and production environments.
public class LocalImageStorageService: ImageStorageService {
    // MARK: - Properties
    
    private var imagesDirectory: URL {
        AppStoragePaths.imagesDirectory
    }
    
    // MARK: - Initialization
    
    public init() {
        try? FileManager.default.createDirectory(at: self.imagesDirectory, withIntermediateDirectories: true)
    }
    
    // MARK: - ImageStorageService Implementation
    
    public func saveImage(_ image: NSImage, date: Date) async throws -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = AppConstants.Formats.imageDateFolder
        let dateFolderName = formatter.string(from: date)
        
        let dateFolderURL = imagesDirectory.appendingPathComponent(dateFolderName, isDirectory: true)
        try? FileManager.default.createDirectory(at: dateFolderURL, withIntermediateDirectories: true)
        
        let fileName = UUID().uuidString + AppConstants.Formats.imageExtension
        let fileURL = dateFolderURL.appendingPathComponent(fileName)
        
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw NSError(domain: AppConstants.Errors.imageDomain, code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to read image pixels"])
        }
        
        let bitmapImage = NSBitmapImageRep(cgImage: cgImage)
        guard let pngData = bitmapImage.representation(using: .png, properties: [:]) else {
            throw NSError(domain: AppConstants.Errors.imageDomain, code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to convert to PNG"])
        }
        
        try pngData.write(to: fileURL)
        
        return "\(dateFolderName)/\(fileName)"
    }
    
    public func getFileURL(for relativePath: String) -> URL {
        return imagesDirectory.appendingPathComponent(relativePath)
    }
    
    public func deleteImage(at relativePath: String) async throws {
        let fileURL = getFileURL(for: relativePath)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }
    }
    
    public func clearAllImages() throws {
        try FileManager.default.removeItem(at: imagesDirectory)
        try FileManager.default.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
    }
    
    public func getBaseDirectory() -> URL {
        return AppStoragePaths.baseDirectory
    }
}
