import SwiftUI

struct NextMeetingCardView: View {
    let event: CalendarEvent
    let onJoin: () -> Void
    @EnvironmentObject private var lm: LocalizationManager

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                // Left accent bar
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.blue)
                    .frame(width: 3)
                    .frame(minHeight: 48)

                VStack(alignment: .leading, spacing: 4) {
                    // Live countdown badge
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        CountdownBadge(event: event, now: context.date)
                            .environmentObject(lm)
                    }

                    Text(event.summary)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    Text(event.timeRangeString)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }

            if let loc = event.location, event.hangoutLink == nil {
                Label(loc, systemImage: "mappin.circle")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            if event.hangoutLink != nil {
                Button(action: onJoin) {
                    Label(lm.str("join"), systemImage: "video.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.blue.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.blue.opacity(0.25), lineWidth: 1)
                )
        )
    }
}

// MARK: - Countdown Badge

private struct CountdownBadge: View {
    let event: CalendarEvent
    let now: Date
    @EnvironmentObject private var lm: LocalizationManager

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(urgencyColor)
                .frame(width: 6, height: 6)
            Text(badgeText)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(urgencyColor)
        }
    }

    private var badgeText: String {
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

    private var urgencyColor: Color {
        let minutes = Int(event.start.timeIntervalSince(now) / 60)
        if minutes <= 0 { return .red }
        if minutes <= 5  { return .red }
        if minutes <= 15 { return .orange }
        return .green
    }
}

// MARK: - Accent Button Style

struct AccentButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.blue.opacity(configuration.isPressed ? 0.7 : 1.0))
            )
    }
}
