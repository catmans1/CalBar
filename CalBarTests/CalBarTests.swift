import Foundation
import Testing
@testable import CalBar

struct CalBarTests {

    // MARK: - Smart Meeting Link Extractor Tests

    @Test func testExtractGoogleMeetLink() {
        let text = "Join with Google Meet: https://meet.google.com/abc-defg-hij and be on time."
        let extracted = MeetingLinkExtractor.extractFirstMeetingURL(from: text)
        #expect(extracted == "https://meet.google.com/abc-defg-hij")
    }

    @Test func testExtractZoomLink() {
        let text = "Topic: Weekly Sync\nJoin Zoom Meeting\nhttps://zoom.us/j/123456789?pwd=abcdef\nPasscode: 12345"
        let extracted = MeetingLinkExtractor.extractFirstMeetingURL(from: text)
        #expect(extracted == "https://zoom.us/j/123456789?pwd=abcdef")
    }

    @Test func testExtractTeamsLink() {
        let text = "Microsoft Teams Meeting: https://teams.microsoft.com/l/meetup-join/19%3ameeting_xyz%40thread.v2/0"
        let extracted = MeetingLinkExtractor.extractFirstMeetingURL(from: text)
        #expect(extracted == "https://teams.microsoft.com/l/meetup-join/19%3ameeting_xyz%40thread.v2/0")
    }

    @Test func testExtractWebexLink() {
        let text = "Webex Room: https://mycompany.webex.com/meet/johndoe"
        let extracted = MeetingLinkExtractor.extractFirstMeetingURL(from: text)
        #expect(extracted == "https://mycompany.webex.com/meet/johndoe")
    }

    @Test func testExtractNoMeetingLink() {
        let text = "Coffee chat at Starbuck on 5th Ave."
        let extracted = MeetingLinkExtractor.extractFirstMeetingURL(from: text)
        #expect(extracted == nil)
    }

    // MARK: - CalendarEvent Model Tests

    @Test func testAllDayEventTimeRange() {
        let start = Date()
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!
        let allDayEvent = CalendarEvent(
            id: "all_day_1",
            summary: "Team Offsite",
            start: start,
            end: end,
            isAllDay: true
        )

        #expect(allDayEvent.isAllDay)
        #expect(!allDayEvent.timeRangeString.contains("00:00 - 00:00"))
        #expect(allDayEvent.timeRangeString == LocalizationManager.shared.str("event.allDay"))
    }

    @Test func testMeetingPlatformDetection() {
        let eventMeet = CalendarEvent(
            id: "1",
            summary: "Sprint Planning",
            start: Date(),
            end: Date().addingTimeInterval(3600),
            hangoutLink: "https://meet.google.com/xyz-abcd-efg"
        )
        #expect(eventMeet.meetingPlatform == .googleMeet)
        #expect(eventMeet.meetingPlatform.iconName == "video.fill")

        let eventZoom = CalendarEvent(
            id: "2",
            summary: "Client Sync",
            start: Date(),
            end: Date().addingTimeInterval(3600),
            location: "https://zoom.us/j/987654321"
        )
        #expect(eventZoom.meetingPlatform == .zoom)
        #expect(eventZoom.meetingPlatform.iconName == "video.bubble.left.fill")
    }

    // MARK: - ICSParser Tests

    @Test func testParseICSData() {
        let icsContent = """
        BEGIN:VCALENDAR
        VERSION:2.0
        PRODID:-//CalBar Test//EN
        BEGIN:VEVENT
        UID:event-123@calbar.app
        SUMMARY:Quarterly Review
        DTSTART:20261015T090000Z
        DTEND:20261015T100000Z
        DESCRIPTION:Reviewing Q3 progress\\, goals\\nand roadmap.
        LOCATION:Room 402\\, Building B
        END:VEVENT
        END:VCALENDAR
        """

        let data = Data(icsContent.utf8)
        let events = ICSParser.parse(data: data)

        #expect(events.count == 1)
        let first = events[0]
        #expect(first.summary == "Quarterly Review")
        #expect(first.location == "Room 402, Building B")
        #expect(first.description?.contains("Reviewing Q3 progress, goals\nand roadmap.") == true)
        #expect(!first.isAllDay)
    }

    @Test func testParseAllDayICSEvent() {
        let icsContent = """
        BEGIN:VCALENDAR
        BEGIN:VEVENT
        SUMMARY:Company Holiday
        DTSTART;VALUE=DATE:20261225
        DTEND;VALUE=DATE:20261226
        END:VEVENT
        END:VCALENDAR
        """

        let data = Data(icsContent.utf8)
        let events = ICSParser.parse(data: data)

        #expect(events.count == 1)
        #expect(events[0].summary == "Company Holiday")
        #expect(events[0].isAllDay == true)
    }

    // MARK: - LocalizationManager Tests

    @Test func testLocalizationManagerKeys() {
        let lm = LocalizationManager.shared
        #expect(!lm.str("app.title").isEmpty)
        #expect(!lm.str("event.allDay").isEmpty)
        #expect(!lm.str("signin.needCredentials").isEmpty)
        #expect(!lm.str("newEvent.create").isEmpty)
    }
}
