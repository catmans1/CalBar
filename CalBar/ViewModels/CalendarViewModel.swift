import Combine
import Foundation
import SwiftUI
import AppKit
import AuthenticationServices

@MainActor
final class CalendarViewModel: ObservableObject {
    @Published var events: [CalendarEvent] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    let auth = AuthManager.shared
    private var refreshTask: Task<Void, Never>?

    var nextMeeting: CalendarEvent? {
        events.first { $0.end > Date() && !$0.isAllDay }
    }

    var todayEvents: [CalendarEvent] {
        let showAllDay = AppSettings.showAllDayEvents
        let maxCount = AppSettings.maxEventsToShow
        let upcoming = events.filter { !showAllDay ? !$0.isAllDay : true }
        // Show up to maxCount future events, plus all past events before them
        let futureEvents = upcoming.filter { $0.end > Date() }.prefix(maxCount)
        let pastEvents = upcoming.filter { $0.end <= Date() }
        return (pastEvents + futureEvents).map { $0 }
    }

    // Kept for backward compatibility with empty-state check
    var upcomingEvents: [CalendarEvent] {
        todayEvents.filter { $0.end > Date() }
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

    func rescheduleNotifications(offsetMinutes: Int) {
        guard AppSettings.notificationsEnabled else { return }
        NotificationManager.shared.scheduleNotifications(for: events, offsetMinutes: offsetMinutes)

        // Second reminder: schedule 1 min before each event
        if AppSettings.enableSecondReminder {
            NotificationManager.shared.scheduleNotifications(for: events, offsetMinutes: 1)
        }
    }
}
