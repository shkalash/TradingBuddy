import SwiftUI
import AppKit

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
