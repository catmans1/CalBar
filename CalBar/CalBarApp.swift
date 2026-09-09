import SwiftUI

@main
struct CalBarApp: App {
    @StateObject private var viewModel = CalendarViewModel()
    @StateObject private var lm = LocalizationManager.shared
    @StateObject private var hotkeyManager = HotkeyManager.shared

    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environmentObject(viewModel)
                .environmentObject(lm)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: viewModel.menuBarIconName)
                if let text = viewModel.menuBarText {
                    Text(text)
                }
            }
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
}
