import SwiftUI

enum SettingsTab: String, CaseIterable, Identifiable {
    case account, calendars, notifications, sync, display, about

    var id: String { rawValue }
    var labelKey: String { "tab.\(rawValue)" }

    var icon: String {
        switch self {
        case .account:       return "person.circle"
        case .calendars:     return "calendar"
        case .notifications: return "bell"
        case .sync:          return "arrow.clockwise"
        case .display:       return "paintbrush"
        case .about:         return "info.circle"
        }
    }
}

struct SettingsView: View {
    @State private var selectedTab: SettingsTab = .account
    @EnvironmentObject var viewModel: CalendarViewModel
    @EnvironmentObject var lm: LocalizationManager

    var body: some View {
        NavigationSplitView {
            List(SettingsTab.allCases, selection: $selectedTab) { tab in
                Label(lm.str(tab.labelKey), systemImage: tab.icon)
                    .tag(tab)
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(160)
        } detail: {
            Group {
                switch selectedTab {
                case .account:       AccountSettingsView()
                case .calendars:     CalendarSettingsView()
                case .notifications: NotificationSettingsView()
                case .sync:          SyncSettingsView()
                case .display:       DisplaySettingsView()
                case .about:         AboutSettingsView()
                }
            }
            .frame(minWidth: 360)
            .environmentObject(viewModel)
            .environmentObject(lm)
        }
        .frame(minWidth: 520, minHeight: 480)
    }
}
