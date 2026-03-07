import Foundation

/// A structured representation of a tag extracted from raw text.
public struct ParsedTag: Equatable {
    public let id: String
    public let type: TagType
}

/// Handles the extraction and normalization of financial tags from user input.
public protocol MessageParser {
    /// Scans text for Futures (/ES), Tickers ($AAPL), and Topics (#tilt).
    func extractTags(from text: String) -> [ParsedTag]
}

/// A regex-based implementation of message parsing.
///
/// **Responsibilities:**
/// - Identifying tag patterns while avoiding false positives (e.g., URLs, email addresses).
/// - Normalizing casing (Uppercase for financial symbols, Lowercase for topics).
public struct RegexMessageParser: MessageParser {
    public init() {}
    
    public func extractTags(from text: String) -> [ParsedTag] {
        var tags: [ParsedTag] = []
        
        // Regex Patterns:
        // (?<!\S) is a negative lookbehind ensuring the tag is at the start of a word/string.
        
        // 1. Futures: Start with / followed by alphanumeric (e.g., /ES, /NQM4)
        tags.append(contentsOf: findMatches(in: text, pattern: "(?<!\\S)/[A-Za-z0-9]+", type: .future))
        
        // 2. Tickers: Start with $ followed by letters (e.g., $AAPL, $SPY)
        tags.append(contentsOf: findMatches(in: text, pattern: "(?<!\\S)\\$[A-Za-z]+", type: .ticker))
        
        // 3. Topics: Start with # followed by alphanumeric or underscores (e.g., #tilt, #eod_review)
        tags.append(contentsOf: findMatches(in: text, pattern: "(?<!\\S)#[A-Za-z0-9_]+", type: .topic))
        
        return tags
    }
    
    private func findMatches(in text: String, pattern: String, type: TagType) -> [ParsedTag] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)
        let matches = regex.matches(in: text, range: nsRange)
        
        return matches.compactMap { match in
            guard let range = Range(match.range, in: text) else { return nil }
            let tagString = String(text[range])
            
            // Normalization Rules:
            // - Futures/Tickers -> Uppercase (standard for symbols)
            // - Topics -> Lowercase (standard for hashtags)
            let normalizedId = type == .topic ? tagString.lowercased() : tagString.uppercased()
            return ParsedTag(id: normalizedId, type: type)
        }
    }
}
