import Combine
import Foundation
import SwiftUI
import AppKit
import AuthenticationServices
import UniformTypeIdentifiers

enum ImportState: Equatable {
    case idle
    case importing(Int, Int)  // current, total
    case success(Int)
    case failure(String)
}

@MainActor
final class CalendarViewModel: ObservableObject {
    @Published var events: [CalendarEvent] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var importState: ImportState = .idle

    let auth = AuthManager.shared
    private var refreshTask: Task<Void, Never>?

    var nextMeeting: CalendarEvent? {
        events.first { $0.end > Date() && !$0.isAllDay }
    }

    var todayEvents: [CalendarEvent] {
        let showAllDay = AppSettings.showAllDayEvents
        let maxCount = AppSettings.maxEventsToShow
        return events
            .filter { $0.end > Date() && (!showAllDay ? !$0.isAllDay : true) }
            .prefix(maxCount)
            .map { $0 }
    }

    var menuBarIconName: String {
        guard AppSettings.showDynamicMenuBarIcon,
              let next = nextMeeting,
              next.minutesUntilStart <= 15 else { return "calendar" }
        return "calendar.badge.exclamationmark"
    }

    init() {
        if auth.isAuthenticated {
            Task {
                await sync()
                startAutoRefresh()
            }
        }
    }

    func sync() async {
        guard auth.isAuthenticated else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            events = try await GoogleCalendarService.shared.fetchTodayEvents()
            rescheduleNotifications(offsetMinutes: AppSettings.notificationOffset)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func startAutoRefresh() {
        refreshTask?.cancel()
        let intervalMinutes = AppSettings.autoRefreshMinutes
        guard intervalMinutes > 0 else { return }
        refreshTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(intervalMinutes) * 60 * 1_000_000_000)
                guard !Task.isCancelled else { return }
                await sync()
            }
        }
    }

    func stopAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    func signIn(contextProvider: ASWebAuthenticationPresentationContextProviding) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await auth.signIn(presentationContextProvider: contextProvider)
            _ = await NotificationManager.shared.requestAuthorization()
            await sync()
            startAutoRefresh()
        } catch AuthError.cancelled {
            // User dismissed — no error
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signOut() {
        stopAutoRefresh()
        auth.signOut()
        events = []
        errorMessage = nil
    }

    func openMeeting(_ event: CalendarEvent) {
        guard let link = event.hangoutLink, let url = URL(string: link) else { return }
        NSWorkspace.shared.open(url)
    }

    // MARK: - ICS Import

    func importICSFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [UTType(filenameExtension: "ics") ?? .data]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.message = "Select an iCal (.ics) file"
        panel.prompt = "Import"

        Task {
            let response: NSApplication.ModalResponse = await withCheckedContinuation { continuation in
                panel.begin { continuation.resume(returning: $0) }
            }
            guard response == .OK, let url = panel.url else { return }

            guard let data = try? Data(contentsOf: url) else {
                showImportState(.failure("Could not read file"))
                return
            }

            let parsed = ICSParser.parse(data: data)
            guard !parsed.isEmpty else {
                showImportState(.failure("No events found in file"))
                return
            }

            importState = .importing(0, parsed.count)
            var imported = 0

            for (i, event) in parsed.enumerated() {
                do {
                    try await GoogleCalendarService.shared.createEvent(event)
                    imported += 1
                } catch ICSImportError.insufficientPermissions {
                    showImportState(.failure("Sign out & sign in again to enable import"))
                    return
                } catch {
                    // Skip individual failures and continue
                }
                importState = .importing(i + 1, parsed.count)
            }

            showImportState(.success(imported))
            if imported > 0 { await sync() }
        }
    }

    private func showImportState(_ state: ImportState) {
        importState = state
        Task {
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            if importState == state { importState = .idle }
        }
    }

    func rescheduleNotifications(offsetMinutes: Int) {
        guard AppSettings.notificationsEnabled else { return }
        NotificationManager.shared.scheduleNotifications(for: events, offsetMinutes: offsetMinutes)

        // Second reminder: schedule 1 min before each event
        if AppSettings.enableSecondReminder {
            NotificationManager.shared.scheduleNotifications(for: events, offsetMinutes: 1)
        }
    }
}
