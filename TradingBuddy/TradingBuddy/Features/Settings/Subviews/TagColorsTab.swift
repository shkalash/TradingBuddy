import SwiftUI

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
