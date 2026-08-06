import SwiftUI

struct CalendarSettingsView: View {
    @State private var calendars: [CalendarListItem] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedIDs: Set<String> = AppSettings.selectedCalendarIDs
    @EnvironmentObject private var lm: LocalizationManager

    var body: some View {
        Form {
            Section {
                if isLoading {
                    HStack { Spacer(); ProgressView(); Spacer() }
                        .padding(.vertical, 8)
                } else if let error = errorMessage {
                    Text(error).foregroundStyle(.red).font(.caption)
                } else if calendars.isEmpty {
                    Text(lm.str("calendars.empty"))
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
        guard AuthManager.shared.isAuthenticated else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
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
