import SwiftUI
import AppKit

// A notification name so we can broadcast when the DB is wiped
extension Notification.Name {
    static let databaseCleared = Notification.Name("TradingBuddy.databaseCleared")
}

struct SettingsView: View {
    let repository: JournalRepository
    let imageStorage: ImageStorageService
    
    @AppStorage("showHistoryJumpWarning") private var showHistoryJumpWarning = true
    @AppStorage("rolloverPromptDelayHours") private var rolloverPromptDelayHours = 2
    
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        VStack(alignment: .leading){
            // BEHAVIOR SECTION
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Warn when typing on historical days", isOn: $showHistoryJumpWarning)
                    
                    HStack {
                        Text("Rollover Snooze Duration:")
                        Stepper(value: $rolloverPromptDelayHours, in: 1...12) {
                            Text("\(rolloverPromptDelayHours) Hours")
                        }
                    }
                }
            } header: {
                Text("Behavior").font(.headline).padding(.bottom, 4)
            }
            
            Divider().padding(.vertical, 8)
            
            // DATA MANAGEMENT SECTION
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    
                    Button("Open App Data Folder in Finder") {
                        NSWorkspace.shared.open(imageStorage.getBaseDirectory())
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Button(role: .destructive, action: { showDeleteConfirmation = true }) {
                            Text("Clear Entire Database...")
                                .foregroundColor(.red)
                        }
                        Text("This action cannot be undone.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("Data").font(.headline).padding(.bottom, 4)
            }
        }
        .padding(30)
        .frame(width: 450)
        
        // 3-BUTTON CONFIRMATION DIALOG
        .confirmationDialog(
            "Are you absolutely sure?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Database & All Saved Images", role: .destructive) {
                Task {
                    try? await repository.clearDatabase()
                    try? imageStorage.clearAllImages()
                    // Tell the main window to update instantly!
                    NotificationCenter.default.post(name: .databaseCleared, object: nil)
                }
            }
            
            Button("Delete Database Only", role: .destructive) {
                Task {
                    try? await repository.clearDatabase()
                    NotificationCenter.default.post(name: .databaseCleared, object: nil)
                }
            }
            
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Wiping your database will permanently remove all your journal entries and tags.")
        }
    }
}
// MARK: - Previews & Mocks

#Preview {
    SettingsView(
        repository: PreviewJournalRepository(),
        imageStorage: PreviewImageStorageService()
    )
}

// Private stubs so Xcode can render the preview without hitting a real SQLite database
private class PreviewJournalRepository: JournalRepository {
    func saveEntry(text: String, imagePath: String?) async throws -> JournalEntry {
        return JournalEntry(id: "1", text: text, timestamp: Date(), tradingDay: Date())
    }
    func updateEntry(id: String, newText: String) async throws {}
    func entries(for day: Date) async throws -> [JournalEntry] { return [] }
    func allTradingDays() async throws -> [Date] { return [] }
    func allTags() async throws -> [Tag] { return [] }
    func entries(forTag tagId: String) async throws -> [JournalEntry] { return [] }
    func clearDatabase() async throws {
        print("Preview: Database cleared")
    }
}

private class PreviewImageStorageService: ImageStorageService {
    func saveImage(_ image: NSImage, date: Date) async throws -> String { "mock.png" }
    func getFileURL(for relativePath: String) -> URL { URL(fileURLWithPath: "/dev/null") }
    func clearAllImages() throws {
        print("Preview: Images cleared")
    }
    func getBaseDirectory() -> URL { URL(fileURLWithPath: "/Users/Shared/") }
}
