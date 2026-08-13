import Foundation

final class GoogleCalendarService {
    static let shared = GoogleCalendarService()
    private init() {}

    // MARK: - Calendar List

    func fetchCalendarList() async throws -> [CalendarListItem] {
        let token = try await AuthManager.shared.validAccessToken()
        var request = URLRequest(url: URL(string: "https://www.googleapis.com/calendar/v3/users/me/calendarList")!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(CalendarListResponse.self, from: data)
        return (response.items ?? []).filter { $0.selected != false }
    }

    // MARK: - Today Events

    func fetchTodayEvents() async throws -> [CalendarEvent] {
        let selectedIDs = AppSettings.selectedCalendarIDs

        if selectedIDs.isEmpty {
            return try await fetchEventsFrom(calendarID: "primary")
        }

        var allEvents: [CalendarEvent] = []
        try await withThrowingTaskGroup(of: [CalendarEvent].self) { group in
            for id in selectedIDs {
                group.addTask { try await self.fetchEventsFrom(calendarID: id) }
            }
            for try await events in group {
                allEvents.append(contentsOf: events)
            }
        }
        return allEvents.sorted { $0.start < $1.start }
    }

    // MARK: - Private

    private func fetchEventsFrom(calendarID: String) async throws -> [CalendarEvent] {
        let token = try await AuthManager.shared.validAccessToken()

        let cal = Calendar.current
        let startOfDay = cal.startOfDay(for: Date())
        let endOfDay   = cal.date(byAdding: .day, value: 1, to: startOfDay)!
        let iso = ISO8601DateFormatter()

        let encodedID = calendarID.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? calendarID
        var comps = URLComponents(string: "https://www.googleapis.com/calendar/v3/calendars/\(encodedID)/events")!
        comps.queryItems = [
            URLQueryItem(name: "timeMin",      value: iso.string(from: startOfDay)),
            URLQueryItem(name: "timeMax",      value: iso.string(from: endOfDay)),
            URLQueryItem(name: "singleEvents", value: "true"),
            URLQueryItem(name: "orderBy",      value: "startTime")
        ]
        guard let url = comps.url else { throw URLError(.badURL) }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        if let http = response as? HTTPURLResponse, http.statusCode == 401 {
            let fresh = try await AuthManager.shared.validAccessToken()
            request.setValue("Bearer \(fresh)", forHTTPHeaderField: "Authorization")
            let (retryData, _) = try await URLSession.shared.data(for: request)
            return try decode(retryData)
        }

        return try decode(data)
    }

    private func decode(_ data: Data) throws -> [CalendarEvent] {
        let list = try JSONDecoder().decode(GoogleCalendarEventList.self, from: data)
        return (list.items ?? []).compactMap { $0.toCalendarEvent() }
    }

    // MARK: - Create Event (import)

    func createEvent(_ event: ParsedICSEvent, calendarID: String = "primary") async throws {
        let encodedID = calendarID.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? calendarID
        let url = URL(string: "https://www.googleapis.com/calendar/v3/calendars/\(encodedID)/events")!
        let token = try await AuthManager.shared.validAccessToken()

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json",  forHTTPHeaderField: "Content-Type")

        var body: [String: Any] = ["summary": event.summary]
        if let desc = event.description, !desc.isEmpty { body["description"] = desc }
        if let loc  = event.location,  !loc.isEmpty   { body["location"]    = loc }

        if event.isAllDay {
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd"
            body["start"] = ["date": f.string(from: event.start)]
            body["end"]   = ["date": f.string(from: event.end)]
        } else {
            let iso = ISO8601DateFormatter()
            iso.formatOptions = [.withInternetDateTime]
            body["start"] = ["dateTime": iso.string(from: event.start), "timeZone": TimeZone.current.identifier]
            body["end"]   = ["dateTime": iso.string(from: event.end),   "timeZone": TimeZone.current.identifier]
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (_, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else { return }
        if http.statusCode == 403 { throw ICSImportError.insufficientPermissions }
        if !(200..<300).contains(http.statusCode) { throw ICSImportError.apiError(http.statusCode) }
    }
}

// MARK: - Import Errors

enum ICSImportError: LocalizedError {
    case insufficientPermissions
    case apiError(Int)

    var errorDescription: String? {
        switch self {
        case .insufficientPermissions:
            return "Sign out and sign in again to enable import"
        case .apiError(let code):
            return "Server error (\(code))"
        }
    }
}
