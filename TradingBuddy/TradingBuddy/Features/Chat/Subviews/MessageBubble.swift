import SwiftUI
import AppKit

/// A localized view representing a single entry in the chat feed.
///
/// **Responsibilities:**
/// - Rendering message text with syntax-highlighted tags.
/// - Displaying attached images with scaled thumbnails.
/// - Providing context menus for copying text or initiating edits.
/// - Normalizing `AttributedString` logic for consistent tag styling.
struct MessageBubble: View {
    // MARK: - Properties
    
    let entry: JournalEntry
    let isFiltered: Bool
    let chatFontSize: Double
    
    var onEdit: (String, String, String?) -> Void
    var onImageTap: (URL) -> Void
    var onJumpToContext: (() -> Void)?
    
    let dependencies: any AppDependencies
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            timestampHeader
            
            VStack(alignment: .leading, spacing: 12) {
                if let imagePath = entry.imagePath {
                    imageThumbnail(path: imagePath)
                }
                
                if !entry.text.isEmpty {
                    messageText
                }
            }
        }
        .padding(16)
        .background(
            Color(nsColor: .controlBackgroundColor)
                // Using a background gesture to avoid conflicts with text selection
                .contentShape(Rectangle())
                .simultaneousGesture(TapGesture(count: 2).onEnded {
                    onJumpToContext?()
                })
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Color.primary.opacity(0.05), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
        .contextMenu { contextButtons }
    }
    
    // MARK: - Components
    
    private var timestampHeader: some View {
        HStack {
            HStack(spacing: 4) {
                // If filtering (tag or search), show the full date
                if isFiltered {
                    Text(entry.tradingDay, format: .dateTime.month().day())
                        .fontWeight(.semibold)
                }
                
                Text(entry.timestamp, format: .dateTime.hour().minute().second())
            }
            .font(.system(size: max(10, chatFontSize - 2)).monospacedDigit())
            .foregroundStyle(.tertiary)
            
            Spacer()
        }
        .padding(.bottom, 2)
    }
    
    private var messageText: some View {
        Text(formatText(entry.text))
            .font(.system(size: chatFontSize))
            .textSelection(.enabled)
            .lineSpacing(4)
    }
    
    private func imageThumbnail(path: String) -> some View {
        let imageURL = dependencies.imageStorage.getFileURL(for: path)
        return Button(action: { onImageTap(imageURL) }) {
            AsyncImage(url: imageURL) { image in
                image.resizable().scaledToFit().frame(maxHeight: 350)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous).strokeBorder(Color.primary.opacity(0.1), lineWidth: 1))
            } placeholder: {
                ProgressView().frame(maxWidth: .infinity, minHeight: 150)
                    .background(Color.primary.opacity(0.05)).cornerRadius(6)
            }
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private var contextButtons: some View {
        Button("chat.message.context.copy") {
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(entry.text, forType: .string)
        }
        Button("chat.message.context.edit") { onEdit(entry.id, entry.text, entry.imagePath) }
        
        if let onJump = onJumpToContext {
            Button("chat.message.context.jump") { onJump() }
        }
    }
    
    // MARK: - Logic
    
    private func formatText(_ rawText: String) -> AttributedString {
        var attributed = AttributedString(rawText)
        let nsString = rawText as NSString
        
        let patterns: [(String, TagType)] = [
            (AppConstants.Patterns.future, .future),
            (AppConstants.Patterns.ticker, .ticker),
            (AppConstants.Patterns.topic, .topic)
        ]
        
        for (pattern, type) in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let matches = regex.matches(in: rawText, range: NSRange(location: 0, length: nsString.length))
                for match in matches {
                    if let swiftRange = Range(match.range, in: rawText),
                       let attrRange = Range<AttributedString.Index>(swiftRange, in: attributed) {
                        attributed[attrRange].foregroundColor = dependencies.colorService.getColor(for: type)
                        attributed[attrRange].font = .system(size: chatFontSize, weight: .semibold, design: .monospaced)
                    }
                }
            }
        }
        return attributed
    }
}
