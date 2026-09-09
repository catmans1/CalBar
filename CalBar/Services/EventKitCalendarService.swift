import Foundation
import EventKit
import SwiftUI

final class EventKitCalendarService {
    static let shared = EventKitCalendarService()
    let eventStore = EKEventStore()

    private init() {}

    // MARK: - Authorization

    var isAuthorized: Bool {
        if #available(macOS 14.0, *) {
            return EKEventStore.authorizationStatus(for: .event) == .fullAccess
        } else {
            return EKEventStore.authorizationStatus(for: .event) == .authorized
        }
    }

    func requestAccess() async -> Bool {
        if #available(macOS 14.0, *) {
            do {
                return try await eventStore.requestFullAccessToEvents()
            } catch {
                return false
            }
        } else {
            return await withCheckedContinuation { continuation in
                eventStore.requestAccess(to: .event) { granted, _ in
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    // MARK: - Fetch Calendars

    func fetchCalendarList() -> [CalendarListItem] {
        guard isAuthorized else { return [] }
        let calendars = eventStore.calendars(for: .event)
        let defaultCal = eventStore.defaultCalendarForNewEvents
        return calendars.map { ekCal in
            let color = Color(nsColor: ekCal.color)
            let isPrimary = (ekCal.calendarIdentifier == defaultCal?.calendarIdentifier)
            return CalendarListItem(
                id: ekCal.calendarIdentifier,
                summary: ekCal.title,
                primary: isPrimary,
                backgroundColor: nil,
                selected: true
            )
        }
    }

    // MARK: - Fetch Today Events

    func fetchTodayEvents() -> [CalendarEvent] {
        guard isAuthorized else { return [] }

        let cal = Calendar.current
        let startOfDay = cal.startOfDay(for: Date())
        let endOfDay = cal.date(byAdding: .day, value: 1, to: startOfDay)!

        let selectedIDs = AppSettings.selectedCalendarIDs
        let allCalendars = eventStore.calendars(for: .event)
        let targetCalendars: [EKCalendar]
        if selectedIDs.isEmpty {
            targetCalendars = allCalendars
        } else {
            targetCalendars = allCalendars.filter { selectedIDs.contains($0.calendarIdentifier) }
        }

        let predicate = eventStore.predicateForEvents(withStart: startOfDay, end: endOfDay, calendars: targetCalendars)
        let ekEvents = eventStore.events(matching: predicate)

        return ekEvents.compactMap { ek in
            guard let start = ek.startDate, let end = ek.endDate else { return nil }
            return CalendarEvent(
                id: ek.eventIdentifier ?? UUID().uuidString,
                summary: ek.title ?? "No Title",
                start: start,
                end: end,
                hangoutLink: ek.url?.absoluteString,
                location: ek.location,
                notes: ek.notes,
                isAllDay: ek.isAllDay
            )
        }.sorted { $0.start < $1.start }
    }

    // MARK: - Create Event

    func createEvent(request: NewEventRequest) throws {
        guard isAuthorized else { throw AppEventKitError.accessDenied }

        let event = EKEvent(eventStore: eventStore)
        event.title = request.summary
        event.startDate = request.start
        event.endDate = request.end
        event.isAllDay = request.isAllDay
        if !request.location.isEmpty { event.location = request.location }
        if !request.notes.isEmpty { event.notes = request.notes }
        event.calendar = eventStore.defaultCalendarForNewEvents ?? eventStore.calendars(for: .event).first

        try eventStore.save(event, span: .thisEvent, commit: true)
    }
}

enum AppEventKitError: LocalizedError {
    case accessDenied

    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Calendar access denied. Please allow calendar access in System Settings."
        }
    }
}
