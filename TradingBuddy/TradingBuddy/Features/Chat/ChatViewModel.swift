import Foundation
import SwiftUI
import Observation
import AppKit
import Combine

/// The central business logic hub for the Chat feature.
///
/// **Responsibilities:**
/// - Managing the message lifecycle (loading, sending, editing).
/// - Handling local search filtering and tag-based views.
/// - Intercepting user actions to provide "History Jump" warnings or "Rollover" prompts.
/// - Coordinating with `JournalRepository` and `ImageStorageService` for data persistence.
/// - Monitoring the system pasteboard for automatic screenshot intake.
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
    private let pasteboardMonitor: PasteboardMonitorProviding

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
    
    public var suggestedTags: [Tag] = []
    
    public var viewedDay: Date
    public var viewedTag: String? = nil
    
    public var highlightedMessageId: String? = nil
    public var pendingScrollId: String? = nil
    private var highlightTask: Task<Void, Never>? = nil
    
    /// Flag to prevent clearing highlight during a jump sequence
    public private(set) var isJumping = false
    
    public var showAlert: Bool = false
    public var activeAlert: AlertType? = nil
    
    private var cancellables = Set<AnyCancellable>()
    
    /// A signal emitted when the chat input should be focused.
    public let focusSignal = PassthroughSubject<Void, Never>()
    
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
        self.pasteboardMonitor = dependencies.pasteboardMonitor
        
        let initialDay = dependencies.session.activeTradingDay
        self.viewedDay = initialDay
        
        setupSubscriptions()
        
        Task {
            await loadSuggestedTags()
        }
    }

    // MARK: - Setup
    
    private func setupSubscriptions() {
        pasteboardMonitor.imagePublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] image in
                self?.handlePasteboardImage(image)
            }
            .store(in: &cancellables)
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
            await loadSuggestedTags()
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
            await loadSuggestedTags()
            NotificationCenter.default.post(name: AppConstants.Notifications.databaseUpdated, object: nil)
        } catch {
            print("ChatViewModel: Failed to load tag entries: \(error)")
        }
    }

    @MainActor
    private func loadSuggestedTags() async {
        do {
            self.suggestedTags = try await repository.topTopicTags(limit: 20)
        } catch {
            print("ChatViewModel: Failed to load suggested tags: \(error)")
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

        // Use the current real time for live messages (today or tag view)
        // This ensures timestamps are correct (not just 00:00:00 normalized day)
        let targetTimestamp = (viewedTag != nil || date == activeTradingDay) ? timeProvider.now : date

        var imagePath: String? = nil
        if let image = pendingImage {
            imagePath = try? await imageStorage.saveImage(image, date: targetTimestamp)
        }

        do {
            _ = try await repository.saveEntry(text: text, imagePath: imagePath, date: targetTimestamp)
            inputText = ""
            pendingImage = nil
            
            if let tag = viewedTag { await load(tag: tag) }
            else { await load(day: viewedDay) }
            await loadSuggestedTags()
        } catch {
            print("ChatViewModel: Failed to save entry: \(error)")
        }
    }

    @MainActor
    public func updateMessage(id: String, newText: String, newImage: NSImage?, imagePath: String?) async {
        do {
            guard let entry = try await repository.entry(id: id) else { return }
            
            var finalImagePath = imagePath
            
            // 1. If the image was removed (imagePath is nil) or replaced (newImage is not nil), 
            // delete the old file if it existed.
            if let oldPath = entry.imagePath, (imagePath == nil || newImage != nil) {
                try? await imageStorage.deleteImage(at: oldPath)
            }
            
            // 2. If a new image is provided, save it.
            if let newImage = newImage {
                finalImagePath = try? await imageStorage.saveImage(newImage, date: entry.tradingDay)
            }
            
            try await repository.updateEntry(id: id, newText: newText, newImagePath: finalImagePath)
            
            if let tag = viewedTag { await load(tag: tag) }
            else { await load(day: viewedDay) }
            await loadSuggestedTags()
        } catch {
            print("ChatViewModel: Failed to update message: \(error)")
        }
    }
    
    public func appendTagToInput(_ tag: Tag) {
        let tagText = tag.id
        if inputText.isEmpty {
            inputText = tagText + " "
        } else if inputText.last == " " {
            inputText += tagText + " "
        } else {
            inputText += " " + tagText + " "
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
                self.isJumping = false // Jump sequence finished
            }
            
            // Keep highlight for long enough to be seen (3 seconds)
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            
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
    
    private func handlePasteboardImage(_ image: NSImage) {
        // Only trigger if monitoring is enabled
        guard preferences.isClipboardMonitoringEnabled else { return }
        
        // 1. Inject image
        self.pendingImage = image
        
        // 2. Clear filters so the user sees the input area in the right context
        self.searchText = ""
        
        // 3. Switch to today
        let today = activeTradingDay
        router.selection = .day(today)
        
        // 4. Force App to front
        NSApp.activate(ignoringOtherApps: true)
        
        // 5. Emit focus signal if enabled
        if preferences.forceFocusChatOnImageIntake {
            focusSignal.send()
        }
    }

    // MARK: - Alert Handlers
    
    @MainActor
    public func handleAlertConfirmation() async {
        showAlert = false
        let today = activeTradingDay
        router.selection = .day(today)
        await load(day: today)
        await performSave(on: today)
        await loadSuggestedTags()
    }

    @MainActor
    public func handleRolloverSnooze() async {
        showAlert = false
        let snoozeHours = preferences.rolloverPromptDelayHours
        preferences.snoozedUntil = timeProvider.now.addingTimeInterval(TimeInterval(snoozeHours * 3600))
        await performSave(on: viewedDay)
        await loadSuggestedTags()
    }

    public func cancelAlert() {
        showAlert = false
        activeAlert = nil
    }
}
