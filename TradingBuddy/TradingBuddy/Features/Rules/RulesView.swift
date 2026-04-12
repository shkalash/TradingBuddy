import SwiftUI
import Textual

/// A view that displays and edits the trading rules.
///
/// **Responsibilities:**
/// - Displaying rules in a full-screen view mode.
/// - Providing an edit mode to modify rules content.
/// - Persisting rules to the app's storage.
struct RulesView: View {
    // MARK: - Properties
    
    let dependencies: any AppDependencies
    @State private var rulesContent: String = ""
    @FocusState private var isEditorFocused: Bool
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            if dependencies.router.rulesMode == .edit {
                TextEditor(text: $rulesContent)
                    .font(.system(.body, design: .monospaced))
                    .padding()
                    .focused($isEditorFocused)
                    .accessibilityIdentifier("rulesEditor")
            } else {
                ScrollView {
                    VStack(alignment: .leading) {
                        if rulesContent.isEmpty {
                            Text(String(localized: "rules.empty_state", defaultValue: "No rules defined. Click edit to add your trading rules."))
                                .foregroundStyle(.secondary)
                                .italic()
                        } else {
                            if ProcessInfo.processInfo.arguments.contains("-UITesting") {
                                    Text(rulesContent)
                                        .accessibilityIdentifier("rulesContent")
                                } else {
                                    StructuredText(markdown: rulesContent)
                                        .textual.structuredTextStyle(.gitHub)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                        }
                    }
                    .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle(String(localized: "rules.navigation.title", defaultValue: "Trading Rules"))
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                Button(action: {
                    dependencies.router.viewMode = .chat
                }) {
                    Label(String(localized: "rules.toolbar.show_chat", defaultValue: "Show Chat"), systemImage: "bubble.left.and.bubble.right")
                }
                .help(String(localized: "rules.toolbar.show_chat.help", defaultValue: "Back to Chat"))
                .accessibilityIdentifier("showChatButton")
                
                if dependencies.router.rulesMode == .edit {
                    Button(action: saveAndExitEditMode) {
                        Label(String(localized: "rules.toolbar.save", defaultValue: "Save"), systemImage: "checkmark.circle.fill")
                    }
                    .keyboardShortcut("s", modifiers: .command)
                    .help(String(localized: "rules.toolbar.save.help", defaultValue: "Save Rules"))
                    .accessibilityIdentifier("saveRulesButton")
                } else {
                    Button(action: {
                        dependencies.router.rulesMode = .edit
                        isEditorFocused = true
                    }) {
                        Label(String(localized: "rules.toolbar.edit", defaultValue: "Edit"), systemImage: "pencil")
                    }
                    .keyboardShortcut("e", modifiers: .command)
                    .help(String(localized: "rules.toolbar.edit.help", defaultValue: "Edit Rules"))
                    .accessibilityIdentifier("editRulesButton")
                }
            }
        }
        .onAppear(perform: loadRules)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("rulesView")
    }
    
    // MARK: - Helpers
    
    private func loadRules() {
        guard !ProcessInfo.processInfo.arguments.contains("-UITesting")
            else { rulesContent = "" ; return }
        rulesContent = dependencies.persistenceHandler.load(for: .rulesContent) ?? ""
    }
    
    private func saveAndExitEditMode() {
        dependencies.persistenceHandler.save(value: rulesContent, for: .rulesContent)
        dependencies.router.rulesMode = .view
        isEditorFocused = false
    }
}

#Preview {
    let mockDeps = PreviewMocks.MockDependencyContainer()
    return RulesView(dependencies: mockDeps)
}
