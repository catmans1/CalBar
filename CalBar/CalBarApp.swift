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
            Image(systemName: viewModel.menuBarIconName)
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
