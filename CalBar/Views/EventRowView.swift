import SwiftUI

struct EventRowView: View {
    let event: CalendarEvent
    let onJoin: () -> Void
    @EnvironmentObject private var lm: LocalizationManager

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(event.summary)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if event.hangoutLink != nil {
                Button(lm.str("join"), action: onJoin)
                    .buttonStyle(AccentButtonStyle())
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.primary.opacity(0.05))
        )
    }

    private var subtitle: String {
        var parts = [event.timeRangeString]
        if event.hangoutLink != nil { parts.append("Google Meet") }
        else if let loc = event.location { parts.append(loc) }
        return parts.joined(separator: " • ")
    }
}
