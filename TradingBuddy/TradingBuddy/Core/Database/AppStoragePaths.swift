import Foundation

public enum AppStoragePaths {
    public static var baseDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        
        #if DEBUG
        let folderURL = appSupport.appendingPathComponent("TradingBuddy-Debug")
        #else
        let folderURL = appSupport.appendingPathComponent("TradingBuddy")
        #endif
        
        if !FileManager.default.fileExists(atPath: folderURL.path) {
            try? FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        }
        
        return folderURL
    }
    
    public static var databaseURL: URL {
        baseDirectory.appendingPathComponent("journal.sqlite")
    }
    
    public static var imagesDirectory: URL {
        let imagesURL = baseDirectory.appendingPathComponent("Images")
        
        if !FileManager.default.fileExists(atPath: imagesURL.path) {
            try? FileManager.default.createDirectory(at: imagesURL, withIntermediateDirectories: true)
        }
        
        return imagesURL
    }
    
    public static var userDefaultsSuiteName: String? {
        #if DEBUG
        return "io.shkalash.TradingBuddy.debug"
        #else
        return nil // Uses standard defaults in production
        #endif
    }
}
