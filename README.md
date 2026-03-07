# TradingBuddy

TradingBuddy is a specialized macOS journal application designed for active traders. It provides a streamlined, chat-inspired interface for logging trades, thoughts, and market observations in real-time, with deep integration for financial identifiers and trading session logic.

## 🎯 Purpose

Traders often need to capture quick thoughts without the friction of complex forms. TradingBuddy mimics the immediacy of a chat app while maintaining the structured persistence required for professional journal review and analysis.

## ✨ Features

- **Chronological Trading Feed:** A clean, familiar chat interface for logging entries throughout the day.
- **Smart Financial Tagging:**
    - **Futures:** Automatic detection and color-coding for instruments like `/ES`, `/NQ`.
    - **Tickers:** Standardized tracking for stock symbols like `$AAPL`, `$NVDA`.
    - **Topics:** Custom thematic tags using hashtags (e.g., `#fomo`, `#setup`).
- **Session-Aware Logic:** Specialized calculation for the Chicago/CME trading day, handling the 5:00 PM CT (6:00 PM ET) rollover and weekend gaps.
- **Visual Evidence:** Instant support for pasting images directly into the feed to capture charts or order fills.
- **Deep Contextual Search:** Powerful filtering by tag or keyword with a "Jump to Context" feature that instantly scrolls to a message's chronological position.
- **Historical Navigation:** A sidebar tree organized by Year and Month for easy review of past sessions.
- **Isolated Persistence:** Separate storage environments for Production, Debug, and Testing to ensure data integrity during development.
- **Fully Localized:** Built from the ground up using modern String Catalogs for multi-language support.

## 🏗 Architecture

This project follows a Feature-Based Layered Architecture. For a deep dive into the technical implementation, patterns, and folder structure, please refer to our:

👉 **[ARCHITECTURE.md](./ARCHITECTURE.md)**

## 🛠 Tech Stack

- **Swift 6**
- **SwiftUI** (with Observation framework)
- **GRDB** (SQLite persistence)
- **Swift Testing**
