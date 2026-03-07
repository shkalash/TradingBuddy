//
//  ChatAlert.swift
//  TradingBuddy
//
//  Created by Shai Kalev on 3/6/26.
//


import Foundation
import Observation
import AppKit

public enum ChatAlert {
    case historyWarning(pendingText: String)
    case rolloverPrompt(pendingText: String)
}

@Observable 
public final class ChatViewModel {
    private let router: AppRouter
    private let repository: JournalRepository
    private let timeProvider: TimeProvider
    private let dayCalculator: TradingDayCalculator
    private var preferences: PreferencesService
    private let imageStorage: ImageStorageService
    
    // UI State
    public var entries: [JournalEntry] = []
    public var searchText: String = ""
    public var viewedDay: Date
    public var viewedTag: String? = nil
    public var activeTradingDay: Date
    public var inputText: String = ""
    public var pendingImage: NSImage? = nil
    
    // Alert State for SwiftUI
    public var activeAlert: ChatAlert?
    public var showAlert: Bool = false
    
    public init(
        repository: JournalRepository,
        timeProvider: TimeProvider,
        dayCalculator: TradingDayCalculator,
        preferences: PreferencesService,
        router: AppRouter,
        imageStorage : ImageStorageService
    ) {
        self.repository = repository
        self.timeProvider = timeProvider
        self.dayCalculator = dayCalculator
        self.preferences = preferences
        self.router = router
        self.imageStorage = imageStorage
        let today = dayCalculator.getTradingDay(for: timeProvider.now)
        self.activeTradingDay = today
        self.viewedDay = today
    }
    
    // Filter entries based on the local search bar
    public var filteredEntries: [JournalEntry] {
        if searchText.isEmpty { return entries }
        return entries.filter { $0.text.localizedCaseInsensitiveContains(searchText) }
    }
    
    
    
    @MainActor
    public func load(tag: String) async {
        self.viewedTag = tag
        // When viewing a tag, we aren't viewing a specific day, but we'll default
        // viewedDay to a past date so the history warning still triggers if they try to type.
        self.viewedDay = Date.distantPast
        do {
            self.entries = try await repository.entries(forTag: tag)
        } catch {
            print("Failed to load entries for tag: \(error)")
        }
    }
    
    @MainActor
    public func load(day: Date) async {
        self.viewedDay = day
        self.viewedTag = nil // Clear tag state
        do {
            self.entries = try await repository.entries(for: day)
        } catch {
            print("Failed to load entries: \(error)")
        }
    }
    
    @MainActor
    public func sendMessage() async {
        let text = self.inputText
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || pendingImage != nil else { return }
        let currentRealTime = timeProvider.now
        let currentCalculatedDay = dayCalculator.getTradingDay(for: currentRealTime)
        // 1. Check for a background Rollover
        if currentCalculatedDay > activeTradingDay {
            let isSnoozed = preferences.snoozedUntil.map { currentRealTime < $0 } ?? false
            if !isSnoozed {
                if viewedDay == activeTradingDay {
                    triggerAlert(.rolloverPrompt(pendingText: text))
                    return
                } else {
                    activeTradingDay = currentCalculatedDay
                }
            }
        }
        // 2. Scenario: User is viewing a historical day
        if viewedDay < activeTradingDay {
            if preferences.showHistoryJumpWarning {
                triggerAlert(.historyWarning(pendingText: text))
                return // Stops here, text is NOT cleared!
            } else {
                await jumpToTodayAndSend(text: text)
                return
            }
        }
        // 3. Normal Send
        await saveAndReload(text: text)
    }
    
    @MainActor
    public func updateMessage(id: String, newText: String) async {
        do {
            try await repository.updateEntry(id: id, newText: newText)
            // Reload the current view so the new text and any new tags populate!
            if let tag = viewedTag {
                await load(tag: tag)
            } else {
                await load(day: viewedDay)
            }
        } catch {
            print("Failed to update entry: \(error)")
        }
    }
    
    @MainActor
    public func handleAlertConfirmation() async {
        guard let alert = activeAlert else { return }
        self.showAlert = false
        self.activeAlert = nil
        
        switch alert {
            case .historyWarning(let text):
                await jumpToTodayAndSend(text: text)
            case .rolloverPrompt(let text):
                // User accepted the new day! Update the tracker now.
                activeTradingDay = dayCalculator.getTradingDay(for: timeProvider.now)
                await jumpToTodayAndSend(text: text)
        }
    }
    
    private func triggerAlert(_ alert: ChatAlert) {
        self.activeAlert = alert
        self.showAlert = true
    }
    
    @MainActor
    public func handleRolloverSnooze() async {
        guard case .rolloverPrompt(let text) = activeAlert else { return }
        self.showAlert = false
        self.activeAlert = nil
        
        // Snooze for 1 hour
        preferences.snoozedUntil = timeProvider.now.addingTimeInterval(3600)
        await saveAndReload(text: text) // Save to the older day
    }
    
    @MainActor
    public func cancelAlert() {
        self.showAlert = false
        self.activeAlert = nil
    }
    
    @MainActor
    private func jumpToTodayAndSend(text: String) async {
        // Tell the app to navigate!
        router.selection = .day(activeTradingDay)
        await saveAndReload(text: text)
    }
    
    @MainActor
        private func saveAndReload(text: String) async {
            do {
                var savedImagePath: String? = nil
                
                if let img = pendingImage {
                    // Pass the viewedDay so it sorts into the correct date folder!
                    savedImagePath = try await imageStorage.saveImage(img, date: viewedDay)
                }
                
                _ = try await repository.saveEntry(text: text, imagePath: savedImagePath)
                
                await load(day: viewedDay)
                self.inputText = ""
                self.pendingImage = nil
            } catch {
                print("Failed to save entry: \(error)")
            }
        }
}
