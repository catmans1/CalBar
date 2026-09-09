import SwiftUI

struct CalendarSettingsView: View {
    @EnvironmentObject var viewModel: CalendarViewModel
    @EnvironmentObject private var lm: LocalizationManager
    @State private var calendars: [CalendarListItem] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedIDs: Set<String> = AppSettings.selectedCalendarIDs

    var body: some View {
        Form {
            Section(lm.str("source.dataSource")) {
                Picker(lm.str("source.dataSource"), selection: Binding(
                    get: { viewModel.calendarSource },
                    set: { newSource in
                        viewModel.setSource(newSource)
                        Task { await loadCalendars() }
                    }
                )) {
                    ForEach(CalendarSource.allCases) { src in
                        Text(lm.str(src.labelKey)).tag(src)
                    }
                }
                .pickerStyle(.radioGroup)

                if viewModel.calendarSource == .appleCalendar && !viewModel.isAppleCalendarAuthorized {
                    Button(lm.str("calendars.grantPermission")) {
                        Task {
                            await viewModel.requestAppleCalendarAccess()
                            await loadCalendars()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 4)
                }
            }

            Section {
                if isLoading {
                    HStack { Spacer(); ProgressView(); Spacer() }
                        .padding(.vertical, 8)
                } else if let error = errorMessage {
                    Text(error).foregroundStyle(.red).font(.caption)
                } else if calendars.isEmpty {
                    Text(viewModel.calendarSource == .appleCalendar ? lm.str("calendars.permissionDenied") : lm.str("calendars.empty"))
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(calendars) { item in
                        Toggle(isOn: calendarBinding(for: item)) {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(item.color)
                                    .frame(width: 10, height: 10)
                                Text(item.displayName)
                                if item.isPrimary {
                                    Text(lm.str("calendars.primary"))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            } header: {
                HStack {
                    Text(lm.str("calendars.header"))
                    Spacer()
                    Button(lm.str("refresh")) { Task { await loadCalendars() } }
                        .buttonStyle(.plain)
                        .font(.caption)
                        .foregroundStyle(Color.blue)
                }
            } footer: {
                Text(lm.str("calendars.footer"))
            }
        }
        .formStyle(.grouped)
        .navigationTitle(lm.str("tab.calendars"))
        .task { await loadCalendars() }
    }

    private func calendarBinding(for item: CalendarListItem) -> Binding<Bool> {
        Binding(
            get: { selectedIDs.isEmpty ? item.isPrimary : selectedIDs.contains(item.id) },
            set: { enabled in
                if enabled { selectedIDs.insert(item.id) }
                else { selectedIDs.remove(item.id) }
                AppSettings.selectedCalendarIDs = selectedIDs
            }
        )
    }

    private func loadCalendars() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        if viewModel.calendarSource == .appleCalendar {
            if !viewModel.isAppleCalendarAuthorized {
                calendars = []
                return
            }
            calendars = EventKitCalendarService.shared.fetchCalendarList()
            if selectedIDs.isEmpty, let primary = calendars.first(where: { $0.isPrimary }) {
                selectedIDs = [primary.id]
                AppSettings.selectedCalendarIDs = selectedIDs
            }
        } else {
            guard AuthManager.shared.isAuthenticated else {
                calendars = []
                return
            }
            do {
                calendars = try await GoogleCalendarService.shared.fetchCalendarList()
                if selectedIDs.isEmpty, let primary = calendars.first(where: { $0.isPrimary }) {
                    selectedIDs = [primary.id]
                    AppSettings.selectedCalendarIDs = selectedIDs
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
