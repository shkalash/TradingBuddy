import Foundation
import SwiftUI
import Observation
import AppKit

/// The central business logic hub for the Chat feature.
///
/// **Responsibilities:**
/// - Managing the message lifecycle (loading, sending, editing).
/// - Handling local search filtering and tag-based views.
/// - Intercepting user actions to provide "History Jump" warnings or "Rollover" prompts.
/// - Coordinating with `JournalRepository` and `ImageStorageService` for data persistence.
@Observable
public final class ChatViewModel {
    // MARK: - Types
    
    public enum AlertType: Equatable {
        case historyWarning
        case rolloverPrompt
    }

    // MARK: - Dependencies
    
    private let repository: JournalRepository
    private let timeProvider: TimeProvider
    private let dayCalculator: TradingDayCalculator
    private var preferences: PreferencesService
    private let router: AppRouter
    private let imageStorage: ImageStorageService

    // MARK: - State
    
    public var entries: [JournalEntry] = []
    public var inputText: String = ""
    
    private var _searchText: String = ""
    public var searchText: String {
        get { _searchText }
        set {
            if _searchText != newValue {
                _searchText = newValue
                clearHighlight()
            }
        }
    }
    
    public var pendingImage: NSImage? = nil
    
    public var viewedDay: Date
    public var viewedTag: String? = nil
    public var activeTradingDay: Date
    
    public var highlightedMessageId: String? = nil
    public var pendingScrollId: String? = nil
    private var highlightTask: Task<Void, Never>? = nil
    
    public var showAlert: Bool = false
    public var activeAlert: AlertType? = nil
    
    // QOL State
    public var chatFontSize: Double {
        get { preferences.chatFontSize }
        set { preferences.chatFontSize = newValue }
    }

    // MARK: - Computed Properties
    
    public var filteredEntries: [JournalEntry] {
        if searchText.isEmpty { return entries }
        return entries.filter { $0.text.localizedCaseInsensitiveContains(searchText) }
    }

    // MARK: - Initialization
    
    public init(
        repository: JournalRepository,
        timeProvider: TimeProvider,
        dayCalculator: TradingDayCalculator,
        preferences: PreferencesService,
        router: AppRouter,
        imageStorage: ImageStorageService
    ) {
        self.repository = repository
        self.timeProvider = timeProvider
        self.dayCalculator = dayCalculator
        self.preferences = preferences
        self.router = router
        self.imageStorage = imageStorage
        
        let initialDay = dayCalculator.getTradingDay(for: timeProvider.now)
        self.activeTradingDay = initialDay
        self.viewedDay = initialDay
    }

    // MARK: - Data Lifecycle
    
    @MainActor
    public func load(day: Date) async {
        clearHighlight()
        self.viewedDay = day
        self.viewedTag = nil
        self.activeTradingDay = dayCalculator.getTradingDay(for: timeProvider.now)
        do {
            self.entries = try await repository.entries(for: day)
        } catch {
            print("ChatViewModel: Failed to load entries: \(error)")
        }
    }

    @MainActor
    public func load(tag: String) async {
        clearHighlight()
        self.viewedTag = tag
        self.activeTradingDay = dayCalculator.getTradingDay(for: timeProvider.now)
        do {
            self.entries = try await repository.entries(forTag: tag)
        } catch {
            print("ChatViewModel: Failed to load tag entries: \(error)")
        }
    }

    // MARK: - Actions
    
    @MainActor
    public func sendMessage() async {
        let now = timeProvider.now
        let currentActiveDay = dayCalculator.getTradingDay(for: now)
        self.activeTradingDay = currentActiveDay

        if let snoozedUntil = preferences.snoozedUntil, now < snoozedUntil {
            // Snoozed, continue
        } else if currentActiveDay != viewedDay && viewedTag == nil {
            activeAlert = .rolloverPrompt
            showAlert = true
            return
        }

        if viewedTag == nil && viewedDay != currentActiveDay && preferences.showHistoryJumpWarning {
            activeAlert = .historyWarning
            showAlert = true
            return
        }

        await performSave(on: viewedDay)
    }

    @MainActor
    private func performSave(on date: Date) async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty || pendingImage != nil else { return }

        let targetDay = viewedTag != nil ? activeTradingDay : date

        var imagePath: String? = nil
        if let image = pendingImage {
            imagePath = try? await imageStorage.saveImage(image, date: targetDay)
        }

        do {
            _ = try await repository.saveEntry(text: text, imagePath: imagePath, date: targetDay)
            inputText = ""
            pendingImage = nil
            
            if let tag = viewedTag { await load(tag: tag) }
            else { await load(day: viewedDay) }
        } catch {
            print("ChatViewModel: Failed to save entry: \(error)")
        }
    }

    @MainActor
    public func updateMessage(id: String, newText: String) async {
        do {
            try await repository.updateEntry(id: id, newText: newText)
            if let tag = viewedTag { await load(tag: tag) }
            else { await load(day: viewedDay) }
        } catch {
            print("ChatViewModel: Failed to update message: \(error)")
        }
    }
    
    @MainActor
    public func jumpToContext(for entry: JournalEntry) async {
        clearHighlight()
        self._searchText = ""
        self.viewedDay = entry.tradingDay
        self.viewedTag = nil
        
        do {
            self.entries = try await repository.entries(for: entry.tradingDay)
        } catch {
            print("ChatViewModel: Failed to load jump entries: \(error)")
            return
        }
        
        highlightTask = Task {
            await MainActor.run { self.pendingScrollId = entry.id }
            
            try? await Task.sleep(nanoseconds: 250_000_000)
            
            if Task.isCancelled { return }
            
            await MainActor.run {
                self.highlightedMessageId = entry.id
                self.pendingScrollId = nil
            }
            
            try? await Task.sleep(nanoseconds: 800_000_000)
            
            if !Task.isCancelled {
                await MainActor.run {
                    self.highlightedMessageId = nil
                }
            }
        }
    }
    
    public func clearHighlight() {
        highlightTask?.cancel()
        highlightTask = nil
        highlightedMessageId = nil
        pendingScrollId = nil
    }
    
    // MARK: - Font Scaling
    
    public func increaseFontSize() {
        if chatFontSize < 30 {
            chatFontSize += 1
        }
    }
    
    public func decreaseFontSize() {
        if chatFontSize > 10 {
            chatFontSize -= 1
        }
    }

    // MARK: - Alert Handlers
    
    @MainActor
    public func handleAlertConfirmation() async {
        showAlert = false
        let today = dayCalculator.getTradingDay(for: timeProvider.now)
        router.selection = .day(today)
        await load(day: today)
        await performSave(on: today)
    }

    @MainActor
    public func handleRolloverSnooze() async {
        showAlert = false
        let snoozeHours = preferences.rolloverPromptDelayHours
        preferences.snoozedUntil = timeProvider.now.addingTimeInterval(TimeInterval(snoozeHours * 3600))
        await performSave(on: viewedDay)
    }

    public func cancelAlert() {
        showAlert = false
        activeAlert = nil
    }
}
