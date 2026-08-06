import SwiftUI

@main
struct CalBarApp: App {
    @StateObject private var viewModel = CalendarViewModel()
    @StateObject private var lm = LocalizationManager.shared

    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environmentObject(viewModel)
                .environmentObject(lm)
        } label: {
            Image(systemName: menuBarIcon)
        }
        .menuBarExtraStyle(.window)

        Window("CalBar Settings", id: "calbar-settings") {
            SettingsView()
                .environmentObject(viewModel)
                .environmentObject(lm)
        }
        .defaultSize(width: 520, height: 520)
        .windowResizability(.contentMinSize)
    }

    private var menuBarIcon: String {
        guard AppSettings.showDynamicMenuBarIcon,
              let next = viewModel.nextMeeting,
              next.minutesUntilStart <= 15 else {
            return "calendar"
        }
        return "calendar.badge.exclamationmark"
    }
}
