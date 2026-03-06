import Foundation

public struct ParsedTag: Equatable {
    public let id: String
    public let type: TagType
}

public protocol MessageParser {
    func extractTags(from text: String) -> [ParsedTag]
}

public struct RegexMessageParser: MessageParser {
    public init() {}
    
    public func extractTags(from text: String) -> [ParsedTag] {
        var tags: [ParsedTag] = []
        
        // 1. Futures: (?<!\S) means "must be preceded by whitespace or start of string"
        tags.append(contentsOf: findMatches(in: text, pattern: "(?<!\\S)/[A-Za-z0-9]+", type: .future))
        
        // 2. Tickers: Letters only after the $
        tags.append(contentsOf: findMatches(in: text, pattern: "(?<!\\S)\\$[A-Za-z]+", type: .ticker))
        
        // 3. Topics: Alphanumeric and underscores after the #
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
            // Standardize tags to uppercase for Futures/Tickers, lowercase for Topics
            let normalizedId = type == .topic ? tagString.lowercased() : tagString.uppercased()
            return ParsedTag(id: normalizedId, type: type)
        }
    }
}
