import SwiftUI
import ServiceManagement

struct SyncSettingsView: View {
    @AppStorage(AppSettings.Keys.autoRefreshInterval) private var refreshInterval: Int = 15
    @AppStorage(AppSettings.Keys.showAllDayEvents)    private var showAllDay: Bool = false
    @State private var launchAtLogin: Bool = (SMAppService.mainApp.status == .enabled)
    @EnvironmentObject var viewModel: CalendarViewModel
    @EnvironmentObject private var lm: LocalizationManager

    var body: some View {
        Form {
            Section(lm.str("sync.auto")) {
                Picker(lm.str("sync.interval"), selection: $refreshInterval) {
                    Text(lm.str("time.5m")).tag(5)
                    Text(lm.str("time.15m")).tag(15)
                    Text(lm.str("time.30m")).tag(30)
                    Text(lm.str("off")).tag(0)
                }
                .onChange(of: refreshInterval) { _, newValue in
                    viewModel.stopAutoRefresh()
                    if newValue > 0 { viewModel.startAutoRefresh() }
                }
            }

            Section {
                Toggle(lm.str("sync.launchAtLogin"), isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, enabled in
                        setLaunchAtLogin(enabled)
                    }
                Toggle(lm.str("sync.showAllDay"), isOn: $showAllDay)
            } header: {
                Text(lm.str("system"))
            } footer: {
                Text(lm.str("sync.footer"))
            }
        }
        .formStyle(.grouped)
        .navigationTitle(lm.str("tab.sync"))
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled { try SMAppService.mainApp.register() }
            else { try SMAppService.mainApp.unregister() }
        } catch {
            launchAtLogin = !enabled
        }
    }
}
