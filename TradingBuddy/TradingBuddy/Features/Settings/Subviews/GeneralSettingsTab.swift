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
    
    @AppStorage(AppConstants.Storage.showHistoryJumpWarningKey) private var showHistoryJumpWarning = true
    @AppStorage(AppConstants.Storage.rolloverPromptDelayHoursKey) private var rolloverPromptDelayHours = 2
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
        .confirmationDialog(
            Text("settings.general.delete_confirm.title"),
            isPresented: $showDeleteConfirmation
        ) {
            confirmationButtons
        }
    }
    
    // MARK: - Components
    
    private var behaviorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("settings.general.behavior.header").font(.headline)
            Toggle("settings.general.behavior.warn_history", isOn: $showHistoryJumpWarning)
            HStack {
                Text("settings.general.behavior.rollover_snooze.label")
                Stepper(value: $rolloverPromptDelayHours, in: 1...12) { 
                    Text("settings.general.behavior.rollover_snooze.value \(rolloverPromptDelayHours)") 
                }
            }
        }
    }
    
    private var dataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("settings.general.data.header").font(.headline)
            Button("settings.general.data.open_folder") { NSWorkspace.shared.open(imageStorage.getBaseDirectory()) }
            VStack(alignment: .leading, spacing: 4) {
                Button(role: .destructive, action: { showDeleteConfirmation = true }) {
                    Text("settings.general.data.clear_db.button").foregroundStyle(.red)
                }
                Text("settings.general.data.clear_db.warning").font(.caption).foregroundStyle(.secondary)
            }
        }
    }
    
    @ViewBuilder
    private var confirmationButtons: some View {
        Button("settings.general.delete_confirm.both", role: .destructive) {
            Task { try? await repository.clearDatabaseAndImages() }
        }
        Button("settings.general.delete_confirm.db_only", role: .destructive) {
            Task { try? await repository.clearDatabaseOnly() }
        }
        Button("settings.general.delete_confirm.cancel", role: .cancel) {}
    }
}
