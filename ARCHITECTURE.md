# TradingBuddy Architecture

This project follows a Feature-Based Layered Architecture designed for maintainability, testability, and clear separation of concerns.

## 1. Architectural Layers

### Core Layer (/Core)
The foundational layer of the application, independent of UI features.
- **Models:** Pure data structures (e.g., JournalEntry, Tag).
- **Protocols:** Definitions for system-wide services to facilitate dependency injection and mocking.
- **Database:** Persistence logic (GRDB) and file system management (Image Storage).

### Feature Layer (/Features)
Organized by user-facing functionality (e.g., Chat, Sidebar, Settings).
- Each feature contains its own Views, ViewModels, and feature-specific logic.
- Uses the MVVM pattern with SwiftUI's Observation framework.

### Navigation Layer (/Navigation)
Manages the application's global state and routing logic (e.g., AppRouter).

### Utilities Layer (/Utilities)
Shared stateless logic and specialized services (e.g., TradingDayService, MessageParserService).

## 2. Key Design Patterns

- **Unidirectional Data Flow:** UI triggers actions on ViewModels, which interact with Repositories, updating state that flows back to the UI.
- **Dependency Injection:** Services are injected into ViewModels via a centralized DependencyContainer to ensure they are easily testable with Mocks.
- **Persistence Isolation:** 
    - Database and Images use a -Debug suffix in non-production builds.
    - UserDefaults uses a dedicated suite (.debug or .unit-tests) to avoid contaminating the developer's personal machine settings.
- **Startup Migrations:** A versioned system for performing one-shot database updates and maintenance tasks (e.g., orphaned tag cleanup) at launch, tracking completion status in persisted preferences.
- **Automated Data Maintenance:** The repository layer handles integrity tasks such as cleaning up orphaned tags during entry updates and through startup migrations.

## 3. Communication

- **Notifications:** Used for broad system events like databaseUpdated or databaseCleared to trigger UI refreshes across disconnected components (e.g., Sidebar and Chat).
- **Observation:** Used for local state management within features, providing a reactive and efficient way to update the UI when data changes.
- **Signals:** Combine PassthroughSubjects are used for specific imperative signals, such as forcing focus on a specific UI element after a background event.
