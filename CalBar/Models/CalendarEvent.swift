import Foundation

struct CalendarEvent: Identifiable, Codable, Equatable {
    let id: String
    let summary: String
    let start: Date
    let end: Date
    let hangoutLink: String?
    let location: String?
    let isAllDay: Bool

    var isUpcoming: Bool { start > Date() }

    var minutesUntilStart: Int {
        max(0, Int(start.timeIntervalSince(Date()) / 60))
    }

    var timeRangeString: String {
        let f = DateFormatter()
        f.dateFormat = AppSettings.use24HourTime ? "HH:mm" : "h:mm a"
        return "\(f.string(from: start)) - \(f.string(from: end))"
    }
}

// MARK: - Google Calendar API Response Models

struct GoogleCalendarEventList: Codable {
    let items: [GoogleCalendarItem]?
}

struct GoogleCalendarItem: Codable {
    let id: String
    let summary: String?
    let start: GoogleEventDateTime?
    let end: GoogleEventDateTime?
    let hangoutLink: String?
    let location: String?
    let conferenceData: ConferenceData?

    func toCalendarEvent() -> CalendarEvent? {
        guard let startDate = start?.toDate(), let endDate = end?.toDate() else { return nil }
        let link = hangoutLink
            ?? conferenceData?.entryPoints?.first(where: { $0.entryPointType == "video" })?.uri
        return CalendarEvent(
            id: id,
            summary: summary ?? "No Title",
            start: startDate,
            end: endDate,
            hangoutLink: link,
            location: location,
            isAllDay: start?.dateTime == nil  // all-day events have no dateTime field
        )
    }
}

struct GoogleEventDateTime: Codable {
    let dateTime: String?
    let date: String?

    func toDate() -> Date? {
        if let dt = dateTime { return ISO8601DateFormatter().date(from: dt) }
        if let d = date {
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd"
            return f.date(from: d)
        }
        return nil
    }
}

struct ConferenceData: Codable {
    let entryPoints: [ConferenceEntryPoint]?
}

struct ConferenceEntryPoint: Codable {
    let entryPointType: String?
    let uri: String?
}
