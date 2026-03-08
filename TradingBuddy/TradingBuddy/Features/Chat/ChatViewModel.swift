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
    private let preferences: PreferencesService
    private let router: AppRouter
    private let imageStorage: ImageStorageService
    private let session: AppSession

    // MARK: - State
    
    public var entries: [JournalEntry] = []
    public var inputText: String = ""
    public var searchText: String = "" {
        didSet {
            if oldValue != searchText {
                clearHighlight()
            }
        }
    }
    
    public var pendingImage: NSImage? = nil
    
    public var viewedDay: Date
    public var viewedTag: String? = nil
    
    public var highlightedMessageId: String? = nil
    public var pendingScrollId: String? = nil
    private var highlightTask: Task<Void, Never>? = nil
    
    /// Flag to prevent clearing highlight during a jump sequence
    private var isJumping = false
    
    public var showAlert: Bool = false
    public var activeAlert: AlertType? = nil
    
    // MARK: - Computed Properties
    
    public var activeTradingDay: Date {
        session.activeTradingDay
    }
    
    public var chatFontSize: Double {
        preferences.chatFontSize
    }
    
    public var filteredEntries: [JournalEntry] {
        if searchText.isEmpty { return entries }
        return entries.filter { $0.text.localizedCaseInsensitiveContains(searchText) }
    }

    // MARK: - Initialization
    
    init(dependencies: any AppDependencies) {
        self.repository = dependencies.repository
        self.timeProvider = dependencies.timeProvider
        self.dayCalculator = dependencies.dayCalculator
        self.preferences = dependencies.preferencesService
        self.router = dependencies.router
        self.imageStorage = dependencies.imageStorage
        self.session = dependencies.session
        
        let initialDay = dependencies.session.activeTradingDay
        self.viewedDay = initialDay
    }

    // MARK: - Data Lifecycle
    
    @MainActor
    public func load(day: Date) async {
        // Optimization: Don't clear highlight if we are reloading the same day
        // or if a jump is currently in progress.
        if !isJumping && (viewedDay != day || viewedTag != nil) {
            clearHighlight()
        }
        
        self.viewedDay = day
        self.viewedTag = nil
        do {
            self.entries = try await repository.entries(for: day)
            NotificationCenter.default.post(name: AppConstants.Notifications.databaseUpdated, object: nil)
        } catch {
            print("ChatViewModel: Failed to load entries: \(error)")
        }
    }

    @MainActor
    public func load(tag: String) async {
        if !isJumping {
            clearHighlight()
        }
        self.viewedTag = tag
        do {
            self.entries = try await repository.entries(forTag: tag)
            NotificationCenter.default.post(name: AppConstants.Notifications.databaseUpdated, object: nil)
        } catch {
            print("ChatViewModel: Failed to load tag entries: \(error)")
        }
    }

    // MARK: - Actions
    
    @MainActor
    public func sendMessage() async {
        let now = timeProvider.now
        let currentActiveDay = activeTradingDay

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
        isJumping = true
        
        // 1. Reset filters
        self.searchText = ""
        
        // 2. Update the Global Router so Sidebar and UI stay in sync
        router.selection = .day(entry.tradingDay)
        
        // 3. Update local state immediately to ensure smooth transition
        self.viewedDay = entry.tradingDay
        self.viewedTag = nil
        
        do {
            self.entries = try await repository.entries(for: entry.tradingDay)
        } catch {
            print("ChatViewModel: Failed to load jump entries: \(error)")
            isJumping = false
            return
        }
        
        // 4. Perform the scroll and highlight
        highlightTask = Task {
            // Give SwiftUI a moment to render the new entries list
            try? await Task.sleep(nanoseconds: 150_000_000)
            
            await MainActor.run { self.pendingScrollId = entry.id }
            
            // Allow time for the ScrollView to perform the animated scroll
            try? await Task.sleep(nanoseconds: 400_000_000)
            
            if Task.isCancelled { 
                await MainActor.run { self.isJumping = false }
                return 
            }
            
            await MainActor.run {
                self.highlightedMessageId = entry.id
                self.pendingScrollId = nil
            }
            
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            
            if !Task.isCancelled {
                await MainActor.run {
                    self.highlightedMessageId = nil
                    self.isJumping = false // Full sequence done
                }
            } else {
                await MainActor.run { self.isJumping = false }
            }
        }
    }
    
    public func clearHighlight() {
        highlightTask?.cancel()
        highlightTask = nil
        highlightedMessageId = nil
        pendingScrollId = nil
        isJumping = false
    }

    // MARK: - Alert Handlers
    
    @MainActor
    public func handleAlertConfirmation() async {
        showAlert = false
        let today = activeTradingDay
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
