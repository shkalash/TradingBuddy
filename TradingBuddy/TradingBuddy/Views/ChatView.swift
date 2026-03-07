//
//  ChatView.swift
//  TradingBuddy
//
//  Created by Shai Kalev on 3/6/26.
//

import SwiftUI

struct ChatView: View {
    @Environment(ChatViewModel.self) private var viewModel
    @State private var isHoveringImage: Bool = false
    @State private var editingEntryId: String? = nil
    @State private var editingText: String = ""
    @State private var previewImageURL: URL? = nil
    @State private var previewPendingImage: NSImage? = nil // <-- NEW: State for pending preview
    
    var body: some View {
        @Bindable var bindableViewModel = viewModel
        
        VStack(spacing: 0) {
            // 1. Message Feed
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        ForEach(viewModel.filteredEntries) { entry in
                            MessageBubble(
                                entry: entry,
                                onEdit: { id, text in
                                    editingText = text
                                    editingEntryId = id
                                },
                                onImageTap: { url in
                                    previewImageURL = url
                                }
                            )
                            .id(entry.id)
                        }
                    }
                    .padding()
                }
                // Auto-scroll to bottom when new messages arrive
                .onChange(of: viewModel.filteredEntries.count) { _, _ in
                    if let last = viewModel.filteredEntries.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }
            
            Divider()
            
            // 2. Floating Input Area
            VStack(alignment: .leading, spacing: 0) {
                // Unified floating background container
                VStack(alignment: .leading, spacing: 0) {
                    
                    // Thumbnail Section (Only shows if there is an image)
                    if let pendingImage = viewModel.pendingImage {
                        // NEW: Wrap the thumbnail in a Button to trigger the preview
                        Button(action: {
                            previewPendingImage = pendingImage
                        }) {
                            Image(nsImage: pendingImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 64, height: 64)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                        .overlay(alignment: .topTrailing) {
                            // Hover-only 'X' button
                            if isHoveringImage {
                                Button(action: { viewModel.pendingImage = nil }) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(6)
                                        .background(Color.black.opacity(0.6))
                                        .clipShape(Circle())
                                }
                                .buttonStyle(.plain)
                                .padding(4)
                            }
                        }
                        .onHover { hovering in
                            withAnimation(.easeInOut(duration: 0.15)) {
                                isHoveringImage = hovering
                            }
                        }
                        .padding(.top, 12)
                        .padding(.horizontal, 16)
                    }
                    
                    // Text Input & Send Button Section
                    HStack(alignment: .bottom) {
                        PasteboardTextView(
                            text: $bindableViewModel.inputText,
                            onImagePasted: { image in
                                viewModel.pendingImage = image
                            },
                            onSubmit: { send() }
                        )
                        .frame(minHeight: 24, maxHeight: 150)
                        .padding(.vertical, 12)
                        
                        // Send Button
                        Button(action: send) {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 16))
                            // Dim the button if there's no text and no image
                                .foregroundColor(viewModel.inputText.isEmpty && viewModel.pendingImage == nil ? .gray : .accentColor)
                                .padding(.bottom, 12)
                        }
                        .buttonStyle(.plain)
                        // Prevent sending if totally empty
                        .disabled(viewModel.inputText.isEmpty && viewModel.pendingImage == nil)
                    }
                    .padding(.horizontal, 16)
                }
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .padding() // Padding from the main window edges to make it "float"
            }
        }
        .sheet(isPresented: Binding(
            get: { editingEntryId != nil },
            set: { if !$0 { editingEntryId = nil } }
        )) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Edit Message").font(.headline)
                
                TextEditor(text: $editingText)
                    .font(.body)
                    .frame(minHeight: 100)
                    .padding(4)
                    .background(Color(nsColor: .textBackgroundColor))
                    .cornerRadius(6)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.3)))
                
                HStack {
                    Spacer()
                    Button("Cancel") { editingEntryId = nil }
                        .keyboardShortcut(.cancelAction)
                    
                    Button("Save") {
                        if let id = editingEntryId {
                            Task {
                                await viewModel.updateMessage(id: id, newText: editingText)
                                editingEntryId = nil
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
        // POST-SEND IMAGE PREVIEW SHEET (URL)
        .sheet(isPresented: Binding(
            get: { previewImageURL != nil },
            set: { if !$0 { previewImageURL = nil } }
        )) {
            if let url = previewImageURL {
                VStack(spacing: 0) {
                    // Top Bar with Close Button
                    HStack {
                        Spacer()
                        Button(action: { previewImageURL = nil }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(6)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .padding()
                        .keyboardShortcut(.cancelAction)
                    }
                    
                    // The giant image
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFit()
                    } placeholder: {
                        ProgressView()
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        // PRE-SEND IMAGE PREVIEW SHEET (NSImage)
        .sheet(isPresented: Binding(
            get: { previewPendingImage != nil },
            set: { if !$0 { previewPendingImage = nil } }
        )) {
            if let nsImage = previewPendingImage {
                VStack(spacing: 0) {
                    // Top Bar with Close Button
                    HStack {
                        Spacer()
                        Button(action: { previewPendingImage = nil }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(6)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .padding()
                        .keyboardShortcut(.cancelAction)
                    }
                    
                    // The giant image
                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFit()
                        .padding(.horizontal, 20)
                }
            }
        }
        // 3. Top Toolbar & Search
        .navigationTitle(
            viewModel.viewedTag != nil
            ? "Tag: \(viewModel.viewedTag!)"
            : viewModel.viewedDay.formatted(.dateTime.month().day().year())
        )
        .searchable(text: $bindableViewModel.searchText, prompt: "Search...")
        
        // 4. Alert Interception
        .alert(
            "Notice",
            isPresented: $bindableViewModel.showAlert,
            presenting: viewModel.activeAlert
        ) { alert in
            switch alert {
                case .historyWarning:
                    Button("Jump to Today") {
                        Task { await viewModel.handleAlertConfirmation() }
                    }
                    Button("Cancel", role: .cancel) {
                        viewModel.cancelAlert()
                    }
                    
                case .rolloverPrompt:
                    Button("Start New Day") {
                        Task { await viewModel.handleAlertConfirmation() }
                    }
                    Button("Snooze (1 Hour)") {
                        Task { await viewModel.handleRolloverSnooze() }
                    }
                    Button("Cancel", role: .cancel) {
                        viewModel.cancelAlert()
                    }
            }
        } message: { alert in
            switch alert {
                case .historyWarning:
                    Text("You are viewing a past day or a tag filter. Do you want to jump to today and save this entry?")
                case .rolloverPrompt:
                    Text("A new trading day has started. Would you like to start a new day entry?")
            }
        }
    }
    
    private func send() {
        Task {
            await viewModel.sendMessage()
        }
    }
}

// MARK: - Subviews

struct MessageBubble: View {
    let entry: JournalEntry
    var onEdit: (String, String) -> Void
    var onImageTap: (URL) -> Void
    
    @Environment(TagColorService.self) private var colorService
    private let storage = LocalImageStorageService()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(entry.timestamp, format: .dateTime.hour().minute().second())
                .font(.caption2)
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 8) {
                if let imagePath = entry.imagePath {
                    let imageURL = storage.getFileURL(for: imagePath)
                    Button(action: { onImageTap(imageURL) }) {
                        AsyncImage(url: imageURL) { image in
                            image.resizable().scaledToFit().frame(maxHeight: 300).cornerRadius(4)
                        } placeholder: {
                            ProgressView().frame(maxWidth: 300, minHeight: 100)
                        }
                    }.buttonStyle(.plain)
                }
                
                if !entry.text.isEmpty {
                    Text(formatText(entry.text))
                        .textSelection(.enabled)
                }
            }
            .padding(12)
            .background(Color.accentColor.opacity(0.1))
            .cornerRadius(8)
            .contextMenu {
                Button("Copy Text") {
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(entry.text, forType: .string)
                }
                
                Button("Edit Message") {
                    onEdit(entry.id, entry.text)
                }
            }
        }
    }
    
    private func formatText(_ rawText: String) -> AttributedString {
        var attributed = AttributedString(rawText)
        let nsString = rawText as NSString
        
        let patterns: [(String, TagType)] = [
            ("(?<!\\S)/[A-Za-z0-9]+", .future),
            ("(?<!\\S)\\$[A-Za-z]+", .ticker),
            ("(?<!\\S)#[A-Za-z0-9_]+", .topic)
        ]
        
        for (pattern, type) in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let matches = regex.matches(in: rawText, range: NSRange(location: 0, length: nsString.length))
                for match in matches {
                    // Accurately target the exact character range in the string
                    if let swiftRange = Range(match.range, in: rawText),
                       let attrRange = Range<AttributedString.Index>(swiftRange, in: attributed) {
                        
                        attributed[attrRange].foregroundColor = colorService.getColor(for: type)
                        attributed[attrRange].font = .system(.body, design: .monospaced, weight: .bold)
                    }
                }
            }
        }
        return attributed
    }
}
