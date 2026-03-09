import Foundation

/// A manager responsible for retrieving sensitive keys from the project's Secrets.plist.
public enum SecretsManager {
    private static var secrets: [String: String] {
        guard let path = Bundle.main.path(forResource: "secrets", ofType: "plist"),
              let dictionary = NSDictionary(contentsOfFile: path) as? [String: String] else {
            return [:]
        }
        return dictionary
    }
    
    /// The API key for Financial Modeling Prep.
    public static var fmpApiKey: String? {
        secrets["FMP_API_KEY"]
    }
}
