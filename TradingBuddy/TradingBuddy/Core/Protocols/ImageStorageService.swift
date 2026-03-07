import Foundation
import AppKit

public protocol ImageStorageService {
    func saveImage(_ image: NSImage, date: Date) async throws -> String
    func getFileURL(for relativePath: String) -> URL
    func clearAllImages() throws
    func getBaseDirectory() -> URL
}
