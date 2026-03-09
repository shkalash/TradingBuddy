import SwiftUI

/// A persistent banner that appears when a high-impact economic event is imminent.
struct NewsBannerView: View {
    // MARK: - Properties
    
    let session: AppSession
    
    // MARK: - Body
    
    var body: some View {
        if let event = session.nextImpendingEvent, let seconds = session.secondsToNextEvent {
            content(event: event, seconds: Int(seconds))
                .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
    
    // MARK: - Subviews
    
    private func content(event: EconomicEvent, seconds: Int) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(event.event)
                    .font(.headline)
                
                Text("news.banner.countdown \(formatTime(seconds))", bundle: .main)
                    .font(.subheadline)
                    .monospacedDigit()
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.red.opacity(0.9))
                .shadow(radius: 4)
        )
        .padding(.horizontal)
        .padding(.top, 8)
        .foregroundStyle(.white)
    }
    
    // MARK: - Helpers
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}

#Preview {
    let mockSession = AppSession(
        dayCalculator: ChicagoTradingDayService(),
        timeProvider: SystemTimeProvider(),
        newsService: FMPEconomicNewsService(apiKey: ""),
        preferences: PreviewMocks.MockPreferences()
    )
    mockSession.nextImpendingEvent = EconomicEvent(
        date: Date().addingTimeInterval(600),
        event: "FOMC Meeting Minutes",
        country: "US",
        impact: "High",
        actual: nil,
        previous: nil,
        estimate: nil,
        unit: nil
    )
    mockSession.secondsToNextEvent = 600
    
    return VStack {
        NewsBannerView(session: mockSession)
            .frame(width: 400)
    }
}
