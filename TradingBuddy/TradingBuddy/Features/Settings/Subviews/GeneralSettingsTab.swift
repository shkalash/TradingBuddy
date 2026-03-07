import SwiftUI

/// A settings tab for managing general application behavior and data.
///
/// **Responsibilities:**
/// - Providing toggles for history jump warnings.
/// - Configuring rollover snooze durations.
/// - Offering destructive actions for database and image management.
struct GeneralSettingsTab: View {
    // MARK: - Properties
    
    let repository: JournalRepository
    let imageStorage: ImageStorageService
    
    @AppStorage("showHistoryJumpWarning") private var showHistoryJumpWarning = true
    @AppStorage("rolloverPromptDelayHours") private var rolloverPromptDelayHours = 2
    @State private var showDeleteConfirmation = false
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            behaviorSection
            Divider()
            dataSection
            Spacer()
        }
        .padding(20)
        .confirmationDialog("Are you absolutely sure?", isPresented: $showDeleteConfirmation) {
            confirmationButtons
        }
    }
    
    // MARK: - Components
    
    private var behaviorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Behavior").font(.headline)
            Toggle("Warn when typing on historical days", isOn: $showHistoryJumpWarning)
            HStack {
                Text("Rollover Snooze Duration:")
                Stepper(value: $rolloverPromptDelayHours, in: 1...12) { Text("\(rolloverPromptDelayHours) Hours") }
            }
        }
    }
    
    private var dataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Data").font(.headline)
            Button("Open App Data Folder in Finder") { NSWorkspace.shared.open(imageStorage.getBaseDirectory()) }
            VStack(alignment: .leading, spacing: 4) {
                Button(role: .destructive, action: { showDeleteConfirmation = true }) {
                    Text("Clear Entire Database...").foregroundStyle(.red)
                }
                Text("This action cannot be undone.").font(.caption).foregroundStyle(.secondary)
            }
        }
    }
    
    @ViewBuilder
    private var confirmationButtons: some View {
        Button("Delete Database & All Saved Images", role: .destructive) {
            Task { try? await repository.clearDatabaseAndImages() }
        }
        Button("Delete Database Only", role: .destructive) {
            Task { try? await repository.clearDatabaseOnly() }
        }
        Button("Cancel", role: .cancel) {}
    }
}
