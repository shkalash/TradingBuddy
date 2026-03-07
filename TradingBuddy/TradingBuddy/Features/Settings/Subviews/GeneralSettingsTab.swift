import SwiftUI

struct GeneralSettingsTab: View {
    let repository: JournalRepository
    let imageStorage: ImageStorageService
    @AppStorage("showHistoryJumpWarning") private var showHistoryJumpWarning = true
    @AppStorage("rolloverPromptDelayHours") private var rolloverPromptDelayHours = 2
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Behavior").font(.headline)
                Toggle("Warn when typing on historical days", isOn: $showHistoryJumpWarning)
                HStack {
                    Text("Rollover Snooze Duration:")
                    Stepper(value: $rolloverPromptDelayHours, in: 1...12) { Text("\(rolloverPromptDelayHours) Hours") }
                }
            }
            Divider()
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
            Spacer()
        }
        .padding(20)
        .confirmationDialog("Are you absolutely sure?", isPresented: $showDeleteConfirmation) {
            Button("Delete Database & All Saved Images", role: .destructive) {
                Task {
                    try? await repository.clearDatabaseAndImages()
                }
            }
            Button("Delete Database Only", role: .destructive) {
                Task {
                    try? await repository.clearDatabaseOnly()
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}
