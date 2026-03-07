//
//  ChatView.swift
//  TradingBuddy
//
//  Created by Shai Kalev on 3/6/26.
//

import SwiftUI
import AppKit

struct ChatView: View {
    @Environment(ChatViewModel.self) private var viewModel
    @State private var editingEntryId: String? = nil
    @State private var editingText: String = ""
    @State private var previewImageURL: URL? = nil
    @State private var previewPendingImage: NSImage? = nil
    
    @State private var isEditing = false
    @State private var isShowingImagePreview = false
    @State private var isShowingPendingImagePreview = false
    
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
                                    isEditing = true
                                },
                                onImageTap: { url in
                                    previewImageURL = url
                                    isShowingImagePreview = true
                                }
                            )
                            .id(entry.id)
                        }
                    }
                    .padding(20)
                }
                .onChange(of: viewModel.filteredEntries.count) { _, _ in
                    if let last = viewModel.filteredEntries.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }
            // A subtle background for the timeline to contrast the bright chat bubbles
            .background(Color(nsColor: .windowBackgroundColor).opacity(0.4))
            
            Divider()
            
            // 2. Floating Input Area
            VStack(alignment: .leading, spacing: 0) {
                
                // Unified Messages-style pill container
                VStack(alignment: .leading, spacing: 8) {
                    
                    // Attached Thumbnail
                    if let pendingImage = viewModel.pendingImage {
                        Button(action: {
                            previewPendingImage = pendingImage
                            isShowingPendingImagePreview = true
                        }) {
                            Image(nsImage: pendingImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 56, height: 56)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                        .overlay(alignment: .topTrailing) {
                            // Native multi-color badge
                            Button(action: { viewModel.pendingImage = nil }) {
                                Image(systemName: "xmark.circle.fill")
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.white, Color.gray.opacity(0.95))
                                    .font(.system(size: 16))
                            }
                            .buttonStyle(.plain)
                            .offset(x: 6, y: -6)
                            .help("Remove Attachment")
                        }
                        .padding(.top, 12)
                        .padding(.horizontal, 14)
                    }
                    
                    // Text Input & Send Button
                    HStack(alignment: .bottom, spacing: 12) {
                        PasteboardTextView(
                            text: $bindableViewModel.inputText,
                            onImagePasted: { image in
                                viewModel.pendingImage = image
                            },
                            onSubmit: { send() }
                        )
                        .frame(minHeight: 22, maxHeight: 150)
                        .padding(.vertical, 12)
                        
                        // Action Button
                        Button(action: send) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 26))
                                .foregroundStyle(viewModel.inputText.isEmpty && viewModel.pendingImage == nil ? Color.gray.opacity(0.3) : .accentColor)
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.inputText.isEmpty && viewModel.pendingImage == nil)
                        .padding(.bottom, 10)
                    }
                    .padding(.horizontal, 14)
                }
                .background(Color(nsColor: .textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 3)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .sheet(isPresented: $isEditing) {
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
                    Button("Cancel") { isEditing = false }
                        .keyboardShortcut(.cancelAction)
                    
                    Button("Save") {
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
        .sheet(isPresented: $isShowingImagePreview) {
            if let url = previewImageURL {
                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        Button(action: { isShowingImagePreview = false }) {
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
        }
        .sheet(isPresented: $isShowingPendingImagePreview) {
            if let nsImage = previewPendingImage {
                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        Button(action: { isShowingPendingImagePreview = false }) {
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
                }
            }
        }
        .navigationTitle(
            viewModel.viewedTag != nil
            ? "Tag: \(viewModel.viewedTag!)"
            : viewModel.viewedDay.formatted(.dateTime.month().day().year())
        )
        .searchable(text: $bindableViewModel.searchText, prompt: "Search...")
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
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(entry.timestamp, format: .dateTime.hour().minute().second())
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.tertiary)
                
                Spacer()
            }
            .padding(.bottom, 2)
            
            VStack(alignment: .leading, spacing: 12) {
                if let imagePath = entry.imagePath {
                    let imageURL = storage.getFileURL(for: imagePath)
                    Button(action: { onImageTap(imageURL) }) {
                        AsyncImage(url: imageURL) { image in
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 350)
                                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
                                )
                        } placeholder: {
                            ProgressView()
                                .frame(maxWidth: .infinity, minHeight: 150)
                                .background(Color.primary.opacity(0.05))
                                .cornerRadius(6)
                        }
                    }
                    .buttonStyle(.plain)
                }
                
                if !entry.text.isEmpty {
                    Text(formatText(entry.text))
                        .textSelection(.enabled)
                        .lineSpacing(4)
                }
            }
        }
        .padding(16)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.05), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
        .contextMenu {
            Button("Copy Text") {
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString(entry.text, forType: .string)
            }
            Button("Edit Message") { onEdit(entry.id, entry.text) }
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
                    if let swiftRange = Range(match.range, in: rawText),
                       let attrRange = Range<AttributedString.Index>(swiftRange, in: attributed) {
                        
                        attributed[attrRange].foregroundColor = colorService.getColor(for: type)
                        attributed[attrRange].font = .system(.body, design: .monospaced, weight: .semibold)
                    }
                }
            }
        }
        return attributed
    }
}
