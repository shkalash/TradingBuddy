import SwiftUI

/// A summary view shown as a modal when a new trading day begins.
struct MorningBriefingView: View {
    // MARK: - Properties
    
    let events: [EconomicEvent]
    let onDismiss: () -> Void
    let onSnooze: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            header
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if events.isEmpty {
                        Text("No high-impact events scheduled for today.")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        ForEach(events) { event in
                            eventRow(event)
                        }
                    }
                }
                .padding()
            }
            
            actions
        }
        .frame(minWidth: 400, minHeight: 300)
    }
    
    // MARK: - Subviews
    
    private var header: some View {
        VStack(spacing: 4) {
            Text("Morning Economic Briefing")
                .font(.title2.bold())
            
            Text("news.briefing.subtitle \(Date().formatted(date: .abbreviated, time: .omitted))")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.top, 24)
        .padding(.bottom, 16)
    }
    
    private func eventRow(_ event: EconomicEvent) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .trailing, spacing: 2) {
                Text(event.date.formatted(date: .omitted, time: .shortened))
                    .font(.headline)
                
                Text(event.country)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 80)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(event.event)
                    .font(.headline)
                
                if let impact = event.impact {
                    Text(impact)
                        .font(.caption.bold())
                        .foregroundColor(impactColor(impact))
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .overlay(
            Divider().opacity(0.5), alignment: .bottom
        )
    }
    
    private var actions: some View {
        HStack(spacing: 12) {
            Button(action: onSnooze) {
                Text("Snooze")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.secondary.opacity(0.2))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
            }
            .buttonStyle(.plain)
            
            Button(action: onDismiss) {
                Text("Get to Trading")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .buttonStyle(.plain)
        }
        .padding(24)
    }
    
    // MARK: - Helpers
    
    private func impactColor(_ impact: String) -> Color {
        switch impact.lowercased() {
        case "high": return .red
        case "medium": return .orange
        case "low": return .green
        default: return .secondary
        }
    }
}

#Preview {
    MorningBriefingView(events: [
        EconomicEvent(date: Date(), event: "FOMC Meeting", country: "US", impact: "High", actual: nil, previous: nil, estimate: nil, unit: nil),
        EconomicEvent(date: Date().addingTimeInterval(3600), event: "Crude Oil Inventories", country: "US", impact: "High", actual: nil, previous: nil, estimate: nil, unit: nil)
    ], onDismiss: {}, onSnooze: {})
}
