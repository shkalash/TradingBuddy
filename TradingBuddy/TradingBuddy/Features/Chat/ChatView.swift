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

/// A context for editing an existing journal entry.
struct EditContext: Identifiable {
    let id: String
    var text: String
    var imagePath: String?
}

/// The primary interface for viewing and sending trading journal entries.
///
/// **Responsibilities:**
/// - Displaying a chronological feed of journal entries.
/// - Providing an input interface for text and image attachments.
/// - Handling image previews and message editing.
/// - Displaying alerts for session rollovers and historical jump warnings.
struct ChatView: View {
    // MARK: - Types
    
    enum FocusField {
        case chatInput
    }
    
    // MARK: - Properties
    
    let dependencies: any AppDependencies
    @State private var viewModel: ChatViewModel
    @FocusState private var focusedField: FocusField?
    
    @State private var editingContext: EditContext? = nil
    
    @State private var activePreviewURL: IdentifiableURL? = nil
    @State private var activePendingPreviewImage: IdentifiableNSImage? = nil
    
    // MARK: - Initialization
    
    init(dependencies: any AppDependencies) {
        self.dependencies = dependencies
        self._viewModel = State(initialValue: ChatViewModel(dependencies: dependencies))
    }
    
    // MARK: - Body
    
    var body: some View {
        @Bindable var bindableViewModel = viewModel
        
        VStack(spacing: 0) {
            Divider()
            
            messageFeed
            
            Divider()
            
            inputArea
        }
        .sheet(item: $editingContext) { context in
            EditSheet(dependencies: dependencies, context: context) { newText, newImage, imagePath in
                Task {
                    await viewModel.updateMessage(id: context.id, newText: newText, newImage: newImage, imagePath: imagePath)
                    editingContext = nil
                }
            } onCancel: {
                editingContext = nil
            }
        }
        .sheet(item: $activePreviewURL) { item in imagePreviewSheet(for: item.url) }
        .sheet(item: $activePendingPreviewImage) { item in pendingImagePreviewSheet(for: item.image) }
        .navigationTitle(navigationTitle)
        .searchable(text: $bindableViewModel.searchText, prompt: Text("chat.search.placeholder"))
        .alert(Text("chat.alert.notice.title"), isPresented: $bindableViewModel.showAlert, presenting: viewModel.activeAlert) { alert in
            alertButtons(for: alert)
        } message: { alert in
            alertMessage(for: alert)
        }
        .task(id: dependencies.router.selection) {
            guard let selection = dependencies.router.selection else { return }
            switch selection {
                case .day(let date): await viewModel.load(day: date)
                case .tag(let tagId): await viewModel.load(tag: tagId)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: AppConstants.Notifications.databaseUpdated)) { _ in
            Task {
                if let selection = dependencies.router.selection {
                    switch selection {
                        case .day(let date): await viewModel.load(day: date)
                        case .tag(let tagId): await viewModel.load(tag: tagId)
                    }
                }
            }
        }
        .onReceive(viewModel.focusSignal) { _ in
            focusedField = .chatInput
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
                            isFiltered: viewModel.viewedTag != nil || !viewModel.searchText.isEmpty,
                            chatFontSize: viewModel.chatFontSize,
                            onEdit: { id, text, imagePath in
                                editingContext = EditContext(id: id, text: text, imagePath: imagePath)
                            },
                            onImageTap: { url in
                                activePreviewURL = IdentifiableURL(url)
                            },
                            onJumpToContext: (viewModel.viewedTag != nil || !viewModel.searchText.isEmpty) ? {
                                Task { await viewModel.jumpToContext(for: entry) }
                            } : nil,
                            dependencies: dependencies
                        )
                        .id(entry.id)
                        .accessibilityIdentifier("messageBubble-\(entry.id)")
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
                // Only scroll to bottom if we are not currently in a jump sequence
                if !viewModel.isJumping && viewModel.highlightedMessageId == nil && viewModel.pendingScrollId == nil, let last = viewModel.filteredEntries.last {
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
        @Bindable var viewModel = viewModel
        return VStack(alignment: .leading, spacing: 0) {
            tagChips
            
            VStack(alignment: .leading, spacing: 8) {
                if let pendingImage = viewModel.pendingImage {
                    attachmentThumbnail(pendingImage)
                }
                
                HStack(alignment: .bottom, spacing: 12) {
                    PasteboardTextView(
                        text: $viewModel.inputText,
                        onImagePasted: { image in
                            viewModel.pendingImage = image
                        },
                        onSubmit: { send() }
                    )
                    .focused($focusedField, equals: .chatInput)
                    .frame(minHeight: 22, maxHeight: 150)
                    .padding(.vertical, 12)
                    .accessibilityIdentifier("chatInput")
                    
                    sendButton
                }
                .padding(.horizontal, 14)
            }
            .background(Color(nsColor: .textBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Color.primary.opacity(0.08), lineWidth: 1))
            .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 3)
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            .padding(.top, 8)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
    
    private var tagChips: some View {
        Group {
            if !viewModel.suggestedTags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 8) {
                        ForEach(viewModel.suggestedTags) { tag in
                            Button(action: { viewModel.appendTagToInput(tag) }) {
                                Text(tag.id)
                                    .font(.system(size: 11, weight: .medium))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(dependencies.colorService.getColor(for: tag.type).opacity(0.1))
                                    .foregroundStyle(dependencies.colorService.getColor(for: tag.type))
                                    .clipShape(Capsule())
                                    .overlay(Capsule().stroke(dependencies.colorService.getColor(for: tag.type).opacity(0.2), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .frame(height: 32)
                }
                .accessibilityIdentifier("tagChipRow")
                .padding(.top, 12)
                .mask {
                    HStack(spacing: 0) {
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0),
                                .init(color: .black, location: 1)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: 24)
                        
                        Rectangle().fill(.black)
                        
                        LinearGradient(
                            stops: [
                                .init(color: .black, location: 0),
                                .init(color: .clear, location: 1)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: 24)
                    }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
    
    // MARK: - Helpers
    
    private var navigationTitle: String {
        if let tag = viewModel.viewedTag {
            return String(localized: "chat.navigation.tag_title \(tag)", comment: "Navigation title for tag view")
        } else {
            return viewModel.viewedDay.formatted(.dateTime.month().day().year())
        }
    }
    
    @MainActor
    private func send() {
        Task { await viewModel.sendMessage() }
    }
    
    struct EditSheet: View {
        let dependencies: any AppDependencies
        let context: EditContext
        var onSave: (String, NSImage?, String?) -> Void
        var onCancel: () -> Void
        
        @State private var text: String = ""
        @State private var currentImagePath: String?
        @State private var pastedImage: NSImage?
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                Text("chat.edit.title").font(.headline)
                
                if let pasted = pastedImage {
                    imagePreview(pasted)
                } else if let path = currentImagePath {
                    existingImagePreview(path)
                }
                
                PasteboardTextView(
                    text: $text,
                    onImagePasted: { image in
                        pastedImage = image
                    },
                    onSubmit: { onSave(text, pastedImage, currentImagePath) }
                )
                .frame(minHeight: 100)
                .padding(4)
                .background(Color(nsColor: .textBackgroundColor))
                .cornerRadius(6)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.3)))
                
                HStack {
                    Spacer()
                    Button("chat.edit.cancel") { onCancel() }.keyboardShortcut(.cancelAction)
                    Button("chat.edit.save") {
                        onSave(text, pastedImage, currentImagePath)
                    }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .frame(width: 400, height: pastedImage != nil || currentImagePath != nil ? 400 : 250)
            .onAppear {
                text = context.text
                currentImagePath = context.imagePath
                pastedImage = nil
            }
        }
        
        private func imagePreview(_ image: NSImage) -> some View {
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 120)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(alignment: .topTrailing) {
                    Button(action: { pastedImage = nil }) {
                        Image(systemName: "xmark.circle.fill")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, Color.gray.opacity(0.9))
                    }
                    .buttonStyle(.plain)
                    .offset(x: 8, y: -8)
                }
        }
        
        private func existingImagePreview(_ path: String) -> some View {
            let url = dependencies.imageStorage.getFileURL(for: path)
            return AsyncImage(url: url) { image in
                image.resizable().scaledToFit()
            } placeholder: {
                ProgressView()
            }
            .frame(maxHeight: 120)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(alignment: .topTrailing) {
                Button(action: { currentImagePath = nil }) {
                    Image(systemName: "xmark.circle.fill")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, Color.gray.opacity(0.9))
                }
                .buttonStyle(.plain)
                .offset(x: 8, y: -8)
            }
        }
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
            .frame(minWidth:800, maxWidth: .infinity , minHeight: 600, maxHeight: .infinity)
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
        .accessibilityIdentifier("sendButton")
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
    let mockDeps = PreviewMocks.MockDependencyContainer()
    return ChatView(dependencies: mockDeps)
}
