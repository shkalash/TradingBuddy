import SwiftUI
import AppKit

extension Notification.Name {
    static let databaseUpdated = Notification.Name("databaseUpdated")
    static let databaseCleared = Notification.Name("TradingBuddy.databaseCleared")
}

struct SettingsView: View {
    let repository: JournalRepository
    let imageStorage: ImageStorageService
    @Environment(TagColorService.self) private var colorService
    var body: some View {
        TabView {
            GeneralSettingsTab(repository: repository, imageStorage: imageStorage)
                .tabItem { Label("General", systemImage: "gearshape") }
            
            TagColorsTab()
                .tabItem { Label("Tags", systemImage: "paintpalette") }
        }
        .frame(width: 450, height: 350)
    }
}

struct TagColorsTab: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Category Colors")
                .font(.headline)
            
            VStack(spacing: 16) {
                CategoryColorRow(title: "Futures (/ES, /NQ)", type: .future)
                CategoryColorRow(title: "Topics (#tilt, #review)", type: .topic)
                CategoryColorRow(title: "Tickers ($AAPL, $SPY)", type: .ticker)
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2)))
            
            Spacer()
        }
        .padding(20)
    }
}

struct CategoryColorRow: View {
    let title: String
    let type: TagType
    
    @Environment(TagColorService.self) private var colorService
    @State private var isShowingPopover = false
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(.body, design: .monospaced))
            
            Spacer()
            
            Circle()
                .fill(colorService.getColor(for: type))
                .frame(width: 24, height: 24)
                .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 1))
                .onTapGesture {
                    isShowingPopover = true
                }
                .popover(isPresented: $isShowingPopover, arrowEdge: .trailing) {
                    // Pass the binding directly so the child can force it to close
                    CategoryColorPopover(
                        type: type,
                        draftColor: colorService.getColor(for: type),
                        isPresented: $isShowingPopover
                    )
                }
        }
    }
}

struct CategoryColorPopover: View {
    let type: TagType
    @State var draftColor: Color
    @Binding var isPresented: Bool
    
    @Environment(TagColorService.self) private var colorService
    @State private var actionTaken = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Select Color").font(.headline)
            
            ColorPicker("Color", selection: $draftColor)
                .labelsHidden()
            
            HStack {
                Button("Cancel") {
                    actionTaken = true
                    closeAllWindows()
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Apply") {
                    actionTaken = true
                    colorService.setColor(draftColor, for: type)
                    closeAllWindows()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(16)
        .frame(width: 220)
        .onDisappear {
            // If they click off the popover (without hitting a button), save it automatically!
            if !actionTaken {
                colorService.setColor(draftColor, for: type)
            }
            
            // If the popover vanishes, ensure the floating Mac color grid vanishes with it
            NSColorPanel.shared.close()
        }
    }
    
    private func closeAllWindows() {
        // 1. Tell SwiftUI to update the state
        isPresented = false
        
        // 2. The Nuclear Option: Send a raw AppKit command up the responder chain to force the Popover closed
        NSApp.sendAction(#selector(NSPopover.performClose(_:)), to: nil, from: nil)
        
        // 3. Force the floating macOS System Color Panel to close
        NSColorPanel.shared.close()
    }
}

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

// MARK: - Previews
#Preview {
    class PreviewImageStorage: ImageStorageService {
        func saveImage(_ image: NSImage, date: Date) async throws -> String { "" }
        func getFileURL(for relativePath: String) -> URL { URL(fileURLWithPath: "") }
        func clearAllImages() throws {}
        func getBaseDirectory() -> URL { URL(fileURLWithPath: "/") }
    }
    
    class PreviewRepo: JournalRepository {
        func clearDatabaseOnly() async throws {}
        func clearDatabaseAndImages() async throws {}
        func saveEntry(text: String, imagePath: String?) async throws -> JournalEntry { JournalEntry(id: "1", text: "", timestamp: Date(), tradingDay: Date()) }
        func updateEntry(id: String, newText: String) async throws {}
        func entries(for day: Date) async throws -> [JournalEntry] { [] }
        func allTradingDays() async throws -> [Date] { [] }
        func allTags() async throws -> [Tag] { [Tag(id: "/ES", type: .future, lastUsed: Date()), Tag(id: "tilt", type: .topic, lastUsed: Date())] }
        func entries(forTag tagId: String) async throws -> [JournalEntry] { [] }
    }
    
    return SettingsView(repository: PreviewRepo(), imageStorage: PreviewImageStorage())
        .environment(TagColorService())
}
