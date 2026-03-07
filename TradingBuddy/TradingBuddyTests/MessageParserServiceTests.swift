import Testing
import Foundation
@testable import TradingBuddy

struct MessageParserServiceTests {
    let parser = RegexMessageParser()

    @Test("Extracts Futures tags correctly and uppercases them")
    func testFuturesExtraction() {
        let text = "Taking a long on /es and a short on /NQM4."
        let tags = parser.extractTags(from: text)
        
        #expect(tags.count == 2)
        #expect(tags.contains(ParsedTag(id: "/ES", type: .future)))
        #expect(tags.contains(ParsedTag(id: "/NQM4", type: .future)))
    }

    @Test("Extracts Ticker tags correctly and uppercases them")
    func testTickerExtraction() {
        let text = "Watching $aapl closely, maybe $TSLA too."
        let tags = parser.extractTags(from: text)
        
        #expect(tags.count == 2)
        #expect(tags.contains(ParsedTag(id: "$AAPL", type: .ticker)))
        #expect(tags.contains(ParsedTag(id: "$TSLA", type: .ticker)))
    }

    @Test("Extracts Topic tags correctly and lowercases them")
    func testTopicExtraction() {
        let text = "Made a bad trade because of #FOMO and #tilt."
        let tags = parser.extractTags(from: text)
        
        #expect(tags.count == 2)
        #expect(tags.contains(ParsedTag(id: "#fomo", type: .topic)))
        #expect(tags.contains(ParsedTag(id: "#tilt", type: .topic)))
    }

    @Test("Extracts all tag types from a single complex message")
    func testMixedTags() {
        let text = "Shorted /NQ because $QQQ was dumping. Total #EOD_review."
        let tags = parser.extractTags(from: text)
        
        #expect(tags.count == 3)
        #expect(tags.contains(ParsedTag(id: "/NQ", type: .future)))
        #expect(tags.contains(ParsedTag(id: "$QQQ", type: .ticker)))
        #expect(tags.contains(ParsedTag(id: "#eod_review", type: .topic)))
    }

    @Test("Ignores tags embedded inside other words")
    func testInvalidTags() {
        // (?<!\S) regex should prevent matching "email@domain.com" or a slash in a web URL
        let text = "Check out https://google.com or email me. That cost $50."
        let tags = parser.extractTags(from: text)
        
        // $50 is a valid regex match for our current setup if we aren't careful,
        // BUT our regex (?<!\S)\$[A-Za-z]+ requires LETTERS after the $. So $50 is ignored.
        #expect(tags.isEmpty)
    }

    @Test("Handles consecutive tags correctly")
    func testConsecutiveTags() {
        let text = "/ES /NQ $AAPL $TSLA #one #two"
        let tags = parser.extractTags(from: text)
        
        #expect(tags.contains(ParsedTag(id: "/ES", type: .future)))
        #expect(tags.contains(ParsedTag(id: "/NQ", type: .future)))
        #expect(tags.contains(ParsedTag(id: "$AAPL", type: .ticker)))
        #expect(tags.contains(ParsedTag(id: "$TSLA", type: .ticker)))
        #expect(tags.contains(ParsedTag(id: "#one", type: .topic)))
        #expect(tags.contains(ParsedTag(id: "#two", type: .topic)))
    }

    @Test("Handles underscores in topic tags")
    func testUnderscoresInTopics() {
        let text = "This is a #great_trade and a #win_win."
        let tags = parser.extractTags(from: text)
        
        #expect(tags.count == 2)
        #expect(tags.contains(ParsedTag(id: "#great_trade", type: .topic)))
        #expect(tags.contains(ParsedTag(id: "#win_win", type: .topic)))
    }
}
