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
}
