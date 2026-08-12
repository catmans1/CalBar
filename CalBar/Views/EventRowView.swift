import SwiftUI

struct EventRowView: View {
    let event: CalendarEvent
    let onJoin: () -> Void
    var isPast: Bool = false
    var isNext: Bool = false
    @EnvironmentObject private var lm: LocalizationManager

    var body: some View {
        HStack {
            // Colored left accent bar for next meeting
            if isNext {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.blue)
                    .frame(width: 3)
                    .padding(.vertical, 4)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(event.summary)
                        .font(.system(size: 12, weight: isNext ? .semibold : .medium))
                        .foregroundStyle(isPast ? .tertiary : .primary)
                        .lineLimit(1)
                    if isNext {
                        TimelineView(.periodic(from: .now, by: 1)) { context in
                            Text(countdown(at: context.date))
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(Color.blue)
                        }
                    }
                }
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundStyle(isPast ? .quaternary : .secondary)
            }
            Spacer()
            if event.hangoutLink != nil && !isPast {
                Button(lm.str("join"), action: onJoin)
                    .buttonStyle(AccentButtonStyle())
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isNext ? Color.blue.opacity(0.08) : Color.primary.opacity(isPast ? 0.02 : 0.05))
                .overlay(
                    isNext ? RoundedRectangle(cornerRadius: 6).stroke(Color.blue.opacity(0.25), lineWidth: 1) : nil
                )
        )
    }

    private func countdown(at now: Date) -> String {
        let seconds = event.start.timeIntervalSince(now)
        if seconds <= 0 { return lm.str("meeting.now") }
        let total = Int(seconds)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        var parts: [String] = []
        if h > 0 { parts.append("\(h)h") }
        if m > 0 { parts.append("\(m)m") }
        if s > 0 || parts.isEmpty { parts.append("\(s)s") }
        return lm.strFormatStr("meeting.inDuration", parts.joined(separator: " "))
    }

    private var subtitle: String {
        var parts = [event.timeRangeString]
        if event.hangoutLink != nil { parts.append("Google Meet") }
        else if let loc = event.location { parts.append(loc) }
        return parts.joined(separator: " • ")
    }
}
