import Foundation

/// A utility providing standardized file system paths for the application's storage needs.
///
/// **Responsibilities:**
/// - Determining the base directory for app data (supporting Debug/Production isolation).
/// - Providing unified paths for the SQLite database and image assets.
/// - Defining suite names for isolated `UserDefaults` storage.
public enum AppStoragePaths {
    // MARK: - Directories
    
    public static var baseDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        
        #if DEBUG
        let folderURL = appSupport.appendingPathComponent(AppConstants.Storage.debugFolder)
        #else
        let folderURL = appSupport.appendingPathComponent(AppConstants.Storage.productionFolder)
        #endif
        
        if !FileManager.default.fileExists(atPath: folderURL.path) {
            try? FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        }
        
        return folderURL
    }
    
    public static var databaseURL: URL {
        baseDirectory.appendingPathComponent(AppConstants.Storage.databaseFileName)
    }
    
    public static var imagesDirectory: URL {
        let imagesURL = baseDirectory.appendingPathComponent(AppConstants.Storage.imagesFolderName)
        
        if !FileManager.default.fileExists(atPath: imagesURL.path) {
            try? FileManager.default.createDirectory(at: imagesURL, withIntermediateDirectories: true)
        }
        
        return imagesURL
    }
    
    // MARK: - UserDefaults
    
    public static var userDefaultsSuiteName: String? {
        #if DEBUG
        return "\(AppConstants.Storage.userDefaultsSuitePrefix).debug"
        #else
        return nil // Uses standard defaults in production
        #endif
    }
}
