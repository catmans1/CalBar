import SwiftUI

struct FooterView: View {
    @AppStorage(AppSettings.Keys.notificationOffset) private var notificationOffset: Int = 5
    @Environment(\.openWindow) private var openWindow
    @EnvironmentObject private var lm: LocalizationManager
    let onOffsetChange: (Int) -> Void
    let onSync: () -> Void
    let onSignOut: () -> Void
    let onImport: () -> Void
    let onNewEvent: () -> Void

    var body: some View {
        HStack {
            HStack(spacing: 6) {
                Text(lm.str("notify.before"))
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                Picker("", selection: $notificationOffset) {
                    Text(lm.str("time.5m")).tag(5)
                    Text(lm.str("time.10m")).tag(10)
                    Text(lm.str("time.15m")).tag(15)
                    Text(lm.str("time.30m")).tag(30)
                }
                .pickerStyle(.menu)
                .frame(minWidth: 80)
                .onChange(of: notificationOffset) { _, newValue in
                    onOffsetChange(newValue)
                }
            }

            Spacer()

            Button(action: onNewEvent) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 12))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help("New event")

            Button(action: onImport) {
                Image(systemName: "arrow.down.doc")
                    .font(.system(size: 12))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help("Import .ics file")

            Button(action: onSync) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 12))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help(lm.str("sync.now"))

            Button {
                openWindow(id: "calbar-settings")
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 12))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help(lm.str("settings"))

            Button(action: onSignOut) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 12))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help(lm.str("sign.out"))
        }
        .padding(.top, 10)
        .overlay(alignment: .top) { Divider() }
    }
}
