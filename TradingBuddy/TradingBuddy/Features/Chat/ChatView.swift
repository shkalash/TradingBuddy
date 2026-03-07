import SwiftUI
import AppKit

/// A wrapper to make URL Identifiable for SwiftUI sheets.
struct IdentifiableURL: Identifiable {
    let id: String
    let url: URL
    init(_ url: URL) {
        self.id = url.absoluteString
        self.url = url
    }
}

/// A wrapper to make NSImage Identifiable for SwiftUI sheets.
struct IdentifiableNSImage: Identifiable {
    let id = UUID()
    let image: NSImage
}

/// The primary interface for viewing and sending trading journal entries.
///
/// **Responsibilities:**
/// - Displaying a chronological feed of journal entries.
/// - Providing an input interface for text and image attachments.
/// - Handling image previews and message editing.
/// - Displaying alerts for session rollovers and historical jump warnings.
struct ChatView: View {
    // MARK: - Properties
    
    @Environment(ChatViewModel.self) private var viewModel
    
    @State private var editingEntryId: String? = nil
    @State private var editingText: String = ""
    
    @State private var activePreviewURL: IdentifiableURL? = nil
    @State private var activePendingPreviewImage: IdentifiableNSImage? = nil
    
    @State private var isEditing = false
    
    // MARK: - Body
    
    var body: some View {
        @Bindable var bindableViewModel = viewModel
        
        VStack(spacing: 0) {
            Divider()
            
            messageFeed
            
            Divider()
            
            inputArea
        }
        .sheet(isPresented: $isEditing) { editSheet }
        .sheet(item: $activePreviewURL) { item in imagePreviewSheet(for: item.url) }
        .sheet(item: $activePendingPreviewImage) { item in pendingImagePreviewSheet(for: item.image) }
        .navigationTitle(navigationTitle)
        .searchable(text: $bindableViewModel.searchText, prompt: Text("chat.search.placeholder"))
        .alert(Text("chat.alert.notice.title"), isPresented: $bindableViewModel.showAlert, presenting: viewModel.activeAlert) { alert in
            alertButtons(for: alert)
        } message: { alert in
            alertMessage(for: alert)
        }
    }
    
    // MARK: - Components
    
    private var messageFeed: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    ForEach(viewModel.filteredEntries) { entry in
                        let isHighlighted = viewModel.highlightedMessageId == entry.id
                        
                        MessageBubble(
                            entry: entry,
                            onEdit: { id, text in
                                editingText = text
                                editingEntryId = id
                                isEditing = true
                            },
                            onImageTap: { url in
                                activePreviewURL = IdentifiableURL(url)
                            },
                            onJumpToContext: (viewModel.viewedTag != nil || !viewModel.searchText.isEmpty) ? {
                                Task { await viewModel.jumpToContext(for: entry) }
                            } : nil
                        )
                        .id(entry.id)
                        .padding(4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.accentColor, lineWidth: 4)
                                .opacity(isHighlighted ? 1 : 0)
                                .scaleEffect(isHighlighted ? 1.01 : 1.0)
                                .animation(isHighlighted ? .easeInOut(duration: 0.2).repeatCount(3, autoreverses: true) : .easeInOut(duration: 0.2), value: isHighlighted)
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .padding(.top, 12)
            }
            .onChange(of: viewModel.filteredEntries.count) { _, _ in
                if viewModel.highlightedMessageId == nil && viewModel.pendingScrollId == nil, let last = viewModel.filteredEntries.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
            .onChange(of: viewModel.pendingScrollId) { _, newId in
                if let id = newId {
                    proxy.scrollTo(id, anchor: .center)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            proxy.scrollTo(id, anchor: .center)
                        }
                    }
                }
            }
        }
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.4))
    }
    
    private var inputArea: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                if let pendingImage = viewModel.pendingImage {
                    attachmentThumbnail(pendingImage)
                }
                
                HStack(alignment: .bottom, spacing: 12) {
                    @Bindable var bindableViewModel = viewModel
                    PasteboardTextView(
                        text: $bindableViewModel.inputText,
                        onImagePasted: { image in
                            viewModel.pendingImage = image
                        },
                        onSubmit: { send() }
                    )
                    .frame(minHeight: 22, maxHeight: 150)
                    .padding(.vertical, 12)
                    
                    sendButton
                }
                .padding(.horizontal, 14)
            }
            .background(Color(nsColor: .textBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Color.primary.opacity(0.08), lineWidth: 1))
            .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 3)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
    
    // MARK: - Helpers
    
    private var navigationTitle: String {
        if let tag = viewModel.viewedTag {
            return String(localized: "chat.navigation.tag_title \(tag)", comment: "Navigation title for tag view")
        } else {
            return viewModel.viewedDay.formatted(.dateTime.month().day().year())
        }
    }
    
    private func send() {
        Task { await viewModel.sendMessage() }
    }
    
    private var editSheet: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("chat.edit.title").font(.headline)
            TextEditor(text: $editingText)
                .font(.body)
                .frame(minHeight: 100)
                .padding(4)
                .background(Color(nsColor: .textBackgroundColor))
                .cornerRadius(6)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.3)))
            
            HStack {
                Spacer()
                Button("chat.edit.cancel") { isEditing = false }.keyboardShortcut(.cancelAction)
                Button("chat.edit.save") {
                    if let id = editingEntryId {
                        Task {
                            await viewModel.updateMessage(id: id, newText: editingText)
                            isEditing = false
                        }
                    }
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 400, height: 250)
    }

    private func imagePreviewSheet(for url: URL) -> some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button(action: { activePreviewURL = nil }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(6)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .padding()
                .keyboardShortcut(.cancelAction)
            }
            AsyncImage(url: url) { image in
                image.resizable().scaledToFit()
            } placeholder: {
                ProgressView()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }

    private func pendingImagePreviewSheet(for nsImage: NSImage) -> some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button(action: { activePendingPreviewImage = nil }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(6)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .padding()
                .keyboardShortcut(.cancelAction)
            }
            Image(nsImage: nsImage)
                .resizable()
                .scaledToFit()
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
        }
    }

    private func attachmentThumbnail(_ image: NSImage) -> some View {
        Button(action: {
            activePendingPreviewImage = IdentifiableNSImage(image: image)
        }) {
            Image(nsImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(Color.primary.opacity(0.1), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .overlay(alignment: .topTrailing) {
            Button(action: { viewModel.pendingImage = nil }) {
                Image(systemName: "xmark.circle.fill")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, Color.gray.opacity(0.95))
                    .font(.system(size: 16))
            }
            .buttonStyle(.plain)
            .offset(x: 6, y: -6)
            .help(Text("chat.input.attachment.remove_help"))
        }
        .padding(.top, 12)
        .padding(.horizontal, 14)
    }

    private var sendButton: some View {
        Button(action: send) {
            Image(systemName: "arrow.up.circle.fill")
                .font(.system(size: 26))
                .foregroundStyle(viewModel.inputText.isEmpty && viewModel.pendingImage == nil ? Color.gray.opacity(0.3) : .accentColor)
        }
        .buttonStyle(.plain)
        .disabled(viewModel.inputText.isEmpty && viewModel.pendingImage == nil)
        .padding(.bottom, 10)
    }

    @ViewBuilder
    private func alertButtons(for alert: ChatViewModel.AlertType) -> some View {
        switch alert {
            case .historyWarning:
                Button("chat.alert.history.jump_today") { Task { await viewModel.handleAlertConfirmation() } }
                Button("chat.alert.history.cancel", role: .cancel) { viewModel.cancelAlert() }
            case .rolloverPrompt:
                Button("chat.alert.rollover.start_new") { Task { await viewModel.handleAlertConfirmation() } }
                Button("chat.alert.rollover.snooze") { Task { await viewModel.handleRolloverSnooze() } }
                Button("chat.alert.rollover.cancel", role: .cancel) { viewModel.cancelAlert() }
        }
    }

    @ViewBuilder
    private func alertMessage(for alert: ChatViewModel.AlertType) -> some View {
        switch alert {
            case .historyWarning:
                Text("chat.alert.history.message")
            case .rolloverPrompt:
                Text("chat.alert.rollover.message")
        }
    }
}

// MARK: - Previews

#Preview {
    ChatView()
        .environment(PreviewMocks.makeChatViewModel())
        .environment(TagColorService())
}
