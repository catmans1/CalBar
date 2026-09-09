import Foundation

enum MeetingPlatform: String {
    case googleMeet = "Google Meet"
    case zoom = "Zoom"
    case msTeams = "Microsoft Teams"
    case webex = "Webex"
    case other = "Meeting"

    var iconName: String {
        switch self {
        case .googleMeet: return "video.fill"
        case .zoom:       return "video.bubble.left.fill"
        case .msTeams:    return "person.2.wave.2.fill"
        case .webex:      return "video.circle.fill"
        case .other:      return "video.fill"
        }
    }
}

struct CalendarEvent: Identifiable, Codable, Equatable {
    let id: String
    let summary: String
    let start: Date
    let end: Date
    let hangoutLink: String?
    let location: String?
    let notes: String?
    let isAllDay: Bool

    init(
        id: String,
        summary: String,
        start: Date,
        end: Date,
        hangoutLink: String? = nil,
        location: String? = nil,
        notes: String? = nil,
        isAllDay: Bool = false
    ) {
        self.id = id
        self.summary = summary
        self.start = start
        self.end = end
        self.hangoutLink = hangoutLink
        self.location = location
        self.notes = notes
        self.isAllDay = isAllDay
    }

    var isUpcoming: Bool { start > Date() }

    var minutesUntilStart: Int {
        max(0, Int(start.timeIntervalSince(Date()) / 60))
    }

    var meetingLink: String? {
        if let hangoutLink, !hangoutLink.isEmpty { return hangoutLink }
        return MeetingLinkExtractor.extractFirstMeetingURL(from: "\(location ?? "") \(notes ?? "")")
    }

    var meetingPlatform: MeetingPlatform {
        guard let link = meetingLink?.lowercased() else { return .other }
        if link.contains("meet.google.com") { return .googleMeet }
        if link.contains("zoom.us") { return .zoom }
        if link.contains("teams.microsoft.com") || link.contains("teams.live.com") { return .msTeams }
        if link.contains("webex.com") { return .webex }
        return .other
    }

    var timeRangeString: String {
        if isAllDay {
            return LocalizationManager.shared.str("event.allDay")
        }
        let formatter = AppSettings.use24HourTime ? DateFormatters.time24 : DateFormatters.time12
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }

    var startTimeString: String {
        if isAllDay {
            return LocalizationManager.shared.str("event.allDay")
        }
        let formatter = AppSettings.use24HourTime ? DateFormatters.time24 : DateFormatters.time12
        return formatter.string(from: start)
    }
}

// MARK: - Smart Meeting Link Extractor

enum MeetingLinkExtractor {
    private static let urlRegex = try? NSRegularExpression(
        pattern: #"https?://[^\s<>\"']+"#,
        options: .caseInsensitive
    )

    static func extractFirstMeetingURL(from text: String) -> String? {
        guard !text.isEmpty, let regex = urlRegex else { return nil }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        let matches = regex.matches(in: text, options: [], range: range)

        for match in matches {
            guard let matchRange = Range(match.range, in: text) else { continue }
            let candidate = String(text[matchRange])
            let lower = candidate.lowercased()
            if lower.contains("meet.google.com/")
                || lower.contains("zoom.us/j/")
                || lower.contains("zoom.us/my/")
                || lower.contains("teams.microsoft.com/l/meetup-join/")
                || lower.contains("teams.live.com/meet/")
                || lower.contains(".webex.com/meet/")
                || lower.contains(".webex.com/join/") {
                return candidate
            }
        }
        return nil
    }
}

// MARK: - Cached Formatters (High Performance)

enum DateFormatters {
    static let time24: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    static let time12: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f
    }()

    static let yyyyMMdd: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static let iso8601: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()
}

// MARK: - Google Calendar API Response Models

struct GoogleCalendarEventList: Codable {
    let items: [GoogleCalendarItem]?
}

struct GoogleCalendarItem: Codable {
    let id: String
    let summary: String?
    let description: String?
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
            notes: description,
            isAllDay: start?.dateTime == nil  // all-day events have no dateTime field
        )
    }
}

struct GoogleEventDateTime: Codable {
    let dateTime: String?
    let date: String?

    func toDate() -> Date? {
        if let dt = dateTime { return DateFormatters.iso8601.date(from: dt) }
        if let d = date { return DateFormatters.yyyyMMdd.date(from: d) }
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
