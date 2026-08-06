import SwiftUI

struct NextMeetingCardView: View {
    let event: CalendarEvent
    let onJoin: () -> Void
    @EnvironmentObject private var lm: LocalizationManager

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 6, height: 6)
                Text(badgeText)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.green)
                    .textCase(.uppercase)
            }

            Text(event.summary)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)

            HStack {
                Text(event.timeRangeString)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                Spacer()
                if event.hangoutLink != nil {
                    Button(lm.str("meeting.join"), action: onJoin)
                        .buttonStyle(AccentButtonStyle())
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(LinearGradient(
                    colors: [Color.blue.opacity(0.2), Color.green.opacity(0.15)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.blue.opacity(0.4), lineWidth: 1)
                )
        )
    }

    private var badgeText: String {
        let m = event.minutesUntilStart
        if m <= 0 { return lm.str("meeting.now") }
        return m == 1 ? lm.str("meeting.inMinute") : lm.strFormat("meeting.inMinutes", m)
    }
}

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
