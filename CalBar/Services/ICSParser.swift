import Foundation

struct ParsedICSEvent {
    let summary: String
    let start: Date
    let end: Date
    let description: String?
    let location: String?
    let isAllDay: Bool
}

enum ICSParser {
    static func parse(data: Data) -> [ParsedICSEvent] {
        guard let text = String(data: data, encoding: .utf8)
                      ?? String(data: data, encoding: .isoLatin1) else { return [] }

        // Unfold continued lines per RFC 5545 section 3.1
        let unfolded = text
            .replacingOccurrences(of: "\r\n ", with: "")
            .replacingOccurrences(of: "\r\n\t", with: "")
            .replacingOccurrences(of: "\n ", with: "")
            .replacingOccurrences(of: "\n\t", with: "")

        var events: [ParsedICSEvent] = []
        var block: [(fullKey: String, value: String)] = []
        var inVEvent = false

        for rawLine in unfolded.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            switch line {
            case "BEGIN:VEVENT":
                inVEvent = true
                block = []
            case "END:VEVENT":
                inVEvent = false
                if let event = makeEvent(from: block) { events.append(event) }
            default:
                guard inVEvent, let colon = line.firstIndex(of: ":") else { continue }
                let fullKey = String(line[..<colon])
                let value   = String(line[line.index(after: colon)...])
                block.append((fullKey: fullKey, value: value))
            }
        }
        return events
    }

    private static func makeEvent(from block: [(fullKey: String, value: String)]) -> ParsedICSEvent? {
        var dict: [String: String] = [:]
        for pair in block {
            let base = pair.fullKey.components(separatedBy: ";").first ?? pair.fullKey
            if dict[base] == nil { dict[base] = pair.value }
        }

        guard let summary = dict["SUMMARY"].map(unescape), !summary.isEmpty else { return nil }

        guard let startPair = block.first(where: { $0.fullKey == "DTSTART" || $0.fullKey.hasPrefix("DTSTART;") }),
              let endPair   = block.first(where: { $0.fullKey == "DTEND"   || $0.fullKey.hasPrefix("DTEND;") })
        else { return nil }

        let isAllDay = startPair.fullKey.contains("VALUE=DATE")
                    || (startPair.value.count == 8 && !startPair.value.contains("T"))

        guard let start = parseDate(fullKey: startPair.fullKey, value: startPair.value),
              let end   = parseDate(fullKey: endPair.fullKey,   value: endPair.value)
        else { return nil }

        return ParsedICSEvent(
            summary:     summary,
            start:       start,
            end:         end,
            description: dict["DESCRIPTION"].map(unescape),
            location:    dict["LOCATION"].map(unescape),
            isAllDay:    isAllDay
        )
    }

    private static func parseDate(fullKey: String, value: String) -> Date? {
        // All-day: VALUE=DATE or 8-char string like "20261001"
        if fullKey.contains("VALUE=DATE") || (value.count == 8 && !value.contains("T")) {
            let f = DateFormatter()
            f.dateFormat = "yyyyMMdd"
            f.timeZone = .current
            return f.date(from: value)
        }

        // UTC: ends with "Z"
        if value.hasSuffix("Z") {
            let f = DateFormatter()
            f.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
            f.timeZone = TimeZone(identifier: "UTC")
            return f.date(from: value)
        }

        // With TZID parameter: DTSTART;TZID=America/New_York:20261001T100000
        let params = fullKey.components(separatedBy: ";")
        if let tzParam = params.first(where: { $0.hasPrefix("TZID=") }) {
            let tzID = String(tzParam.dropFirst(5))
            let f = DateFormatter()
            f.dateFormat = "yyyyMMdd'T'HHmmss"
            f.timeZone = TimeZone(identifier: tzID) ?? .current
            return f.date(from: value)
        }

        // Local time (no timezone)
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd'T'HHmmss"
        f.timeZone = .current
        return f.date(from: value)
    }

    private static func unescape(_ s: String) -> String {
        s.replacingOccurrences(of: "\\,",  with: ",")
         .replacingOccurrences(of: "\\;",  with: ";")
         .replacingOccurrences(of: "\\n",  with: "\n")
         .replacingOccurrences(of: "\\N",  with: "\n")
         .replacingOccurrences(of: "\\\\", with: "\\")
    }
}
