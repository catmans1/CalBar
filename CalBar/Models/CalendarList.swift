import Foundation
import SwiftUI

// MARK: - Google Calendar List API Models

struct CalendarListResponse: Codable {
    let items: [CalendarListItem]?
}

struct CalendarListItem: Identifiable, Codable {
    let id: String
    let summary: String
    let backgroundColor: String?
    let primary: Bool?
    let selected: Bool?

    var displayName: String { summary }
    var isPrimary: Bool { primary == true }
    var color: Color { Color(hex: backgroundColor ?? "#4285F4") ?? .blue }
}

// MARK: - Color Hex Extension

extension Color {
    init?(hex: String) {
        var hex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if hex.hasPrefix("#") { hex = String(hex.dropFirst()) }
        guard hex.count == 6, let value = UInt64(hex, radix: 16) else { return nil }
        self.init(
            red:   Double((value >> 16) & 0xFF) / 255.0,
            green: Double((value >> 8)  & 0xFF) / 255.0,
            blue:  Double(value         & 0xFF) / 255.0
        )
    }
}
