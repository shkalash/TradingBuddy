import Foundation
import AppKit

/// Handles physical storage and retrieval of image assets on the local file system.
///
/// **Responsibilities:**
/// - Converting `NSImage` data to PNG format for disk storage.
/// - Managing directory structures organized by date.
/// - Providing absolute file URLs for UI rendering.
public protocol ImageStorageService {
    func saveImage(_ image: NSImage, date: Date) async throws -> String
    func deleteImage(at relativePath: String) async throws
    func getFileURL(for relativePath: String) -> URL
    func clearAllImages() throws
    func getBaseDirectory() -> URL
}
