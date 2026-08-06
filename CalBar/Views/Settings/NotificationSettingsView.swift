import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {
    @AppStorage(AppSettings.Keys.notificationsEnabled)  private var enabled: Bool = true
    @AppStorage(AppSettings.Keys.notificationOffset)    private var offset: Int = 5
    @AppStorage(AppSettings.Keys.enableSecondReminder)  private var secondReminder: Bool = false
    @EnvironmentObject var viewModel: CalendarViewModel
    @EnvironmentObject private var lm: LocalizationManager

    var body: some View {
        Form {
            Section {
                Toggle(lm.str("notif.enable"), isOn: $enabled)
                    .onChange(of: enabled) { _, on in
                        if on {
                            Task { _ = await NotificationManager.shared.requestAuthorization() }
                        } else {
                            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                        }
                    }

                Picker(lm.str("notif.before"), selection: $offset) {
                    Text(lm.str("time.5m")).tag(5)
                    Text(lm.str("time.10m")).tag(10)
                    Text(lm.str("time.15m")).tag(15)
                    Text(lm.str("time.30m")).tag(30)
                }
                .disabled(!enabled)
                .onChange(of: offset) { _, newValue in
                    viewModel.rescheduleNotifications(offsetMinutes: newValue)
                }

                Toggle(lm.str("notif.secondReminder"), isOn: $secondReminder)
                    .disabled(!enabled)
                    .onChange(of: secondReminder) { _, _ in
                        viewModel.rescheduleNotifications(offsetMinutes: offset)
                    }
            } header: {
                Text(lm.str("notif.header"))
            } footer: {
                Text(lm.str("notif.footer"))
            }
        }
        .formStyle(.grouped)
        .navigationTitle(lm.str("tab.notifications"))
    }
}
