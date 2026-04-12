# TradingBuddy

TradingBuddy is a specialized macOS journal application designed for active traders. It provides a streamlined, chat-inspired interface for logging trades, thoughts, and market observations in real-time, with deep integration for financial identifiers and trading session logic.

## Purpose

Traders often need to capture quick thoughts without the friction of complex forms. TradingBuddy mimics the immediacy of a chat app while maintaining the structured persistence required for professional journal review and analysis.

## Features

- **Chronological Trading Feed:** A clean, familiar chat interface for logging entries throughout the day.
- **Smart Financial Tagging:**
    - **Futures:** Automatic detection and color-coding for instruments like /ES, /NQ.
    - **Tickers:** Standardized tracking for stock symbols like $AAPL, $NVDA.
    - **Topics:** Custom thematic tags using hashtags (e.g., #try-this, #multi_word-tag). Supports hyphens and underscores.
- **Tag Suggestion Chips:** A horizontally scrolling list of the 20 most-referenced topic tags displayed above the input field for instant insertion into your draft.
- **Session-Aware Logic:** Specialized calculation for the Chicago/CME trading day, handling the 5:00 PM CT (6:00 PM ET) rollover and weekend gaps.
- **Visual Evidence:** Support for pasting images directly into the feed to capture charts or order fills.
- **Deep Contextual Search:** Powerful filtering by tag or keyword with a "Jump to Context" feature that instantly scrolls to a message's chronological position.
- **Organized Sidebar Navigation:**
    - **History Tree:** Navigation organized by Year and Month for easy review of past sessions.
    - **Alphanumeric Tag Sorting:** Tags are automatically sorted alphabetically (A-Z) for consistent organization.
    - **Automatic Cleanup:** Orphaned tags with no remaining messages are automatically removed to keep the interface focused.
- **Dedicated Trading Rules View:** Provides a dedicted central no distraction view to keep the most important rules front and center

## Architecture

This project follows a Feature-Based Layered Architecture. For a deep dive into the technical implementation, patterns, and folder structure, please refer to our:

**[ARCHITECTURE.md](./ARCHITECTURE.md)**

## Tech Stack

- **Swift 6**
- **SwiftUI** (with Observation framework)
- **GRDB** (SQLite persistence)
- **Swift Testing**
