import SwiftUI

/// A settings tab for managing general application behavior and data.
///
/// **Responsibilities:**
/// - Providing toggles for history jump warnings.
/// - Configuring rollover snooze durations.
/// - Offering destructive actions for database and image management.
struct GeneralSettingsTab: View {
    // MARK: - Properties
    
    let dependencies: any AppDependencies
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
            
            Toggle("settings.general.behavior.warn_history", isOn: Binding(
                get: { dependencies.preferencesService.showHistoryJumpWarning },
                set: { dependencies.preferencesService.showHistoryJumpWarning = $0 }
            ))
            
            HStack {
                Text("settings.general.behavior.rollover_snooze.label")
                Stepper(value: Binding(
                    get: { dependencies.preferencesService.rolloverPromptDelayHours },
                    set: { dependencies.preferencesService.rolloverPromptDelayHours = $0 }
                ), in: 1...12) {
                    Text("settings.general.behavior.rollover_snooze.value \(dependencies.preferencesService.rolloverPromptDelayHours)")
                }
            }
        }
    }
    
    private var dataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("settings.general.data.header").font(.headline)
            Button("settings.general.data.open_folder") { NSWorkspace.shared.open(dependencies.imageStorage.getBaseDirectory()) }
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
            Task { await dependencies.commands.resetDatabase(includingImages: true) }
        }
        Button("settings.general.delete_confirm.db_only", role: .destructive) {
            Task { await dependencies.commands.resetDatabase(includingImages: false) }
        }
        Button("settings.general.delete_confirm.cancel", role: .cancel) {}
    }
}
