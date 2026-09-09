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
    @Published var showNewEvent = false
    @Published var isCreatingEvent = false
    @Published var createEventError: String?

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

    var menuBarText: String? {
        let mode = AppSettings.menuBarDisplayMode
        guard mode != .iconOnly, let next = nextMeeting else { return nil }

        let mins = next.minutesUntilStart
        let timeStr: String
        if mins == 0 {
            timeStr = LocalizationManager.shared.str("meeting.now")
        } else if mins < 60 {
            timeStr = "\(mins)m"
        } else {
            let h = mins / 60
            let m = mins % 60
            timeStr = m > 0 ? "\(h)h\(m)m" : "\(h)h"
        }

        switch mode {
        case .iconOnly:
            return nil
        case .countdown:
            return timeStr
        case .titleAndCountdown:
            let truncatedTitle = next.summary.count > 18 ? "\(next.summary.prefix(16))…" : next.summary
            return "\(truncatedTitle) (\(timeStr))"
        }
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
        guard AppSettings.hasConfiguredCredentials else {
            errorMessage = LocalizationManager.shared.str("signin.needCredentials")
            return
        }
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
        guard let link = event.meetingLink, let url = URL(string: link) else { return }
        NSWorkspace.shared.open(url)
    }

    // MARK: - Create Event

    func createNewEvent(_ request: NewEventRequest) async {
        isCreatingEvent = true
        createEventError = nil
        defer { isCreatingEvent = false }
        do {
            try await GoogleCalendarService.shared.createEvent(request: request)
            showNewEvent = false
            await sync()
        } catch ICSImportError.insufficientPermissions {
            createEventError = LocalizationManager.shared.str("newEvent.errorAuth")
        } catch {
            createEventError = error.localizedDescription
        }
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
        var offsets = [offsetMinutes]
        if AppSettings.enableSecondReminder && !offsets.contains(1) {
            offsets.append(1)
        }
        NotificationManager.shared.scheduleNotifications(for: events, offsets: offsets)
    }
}
