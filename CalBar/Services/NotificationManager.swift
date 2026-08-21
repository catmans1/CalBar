import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    func requestAuthorization() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])) ?? false
    }

    func scheduleNotifications(for events: [CalendarEvent], offsets: [Int]) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        let now = Date()
        for event in events {
            for offsetMinutes in offsets {
                let triggerDate = event.start.addingTimeInterval(Double(-offsetMinutes * 60))
                guard triggerDate > now else { continue }

                let content = UNMutableNotificationContent()
                content.title = event.summary
                content.body = offsetMinutes <= 1
                    ? "Starting now • \(event.timeRangeString)"
                    : "Starts in \(offsetMinutes) min • \(event.timeRangeString)"
                content.sound = .default
                if let link = event.hangoutLink {
                    content.userInfo = ["url": link]
                }

                let comps = Calendar.current.dateComponents(
                    [.year, .month, .day, .hour, .minute, .second],
                    from: triggerDate
                )
                let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
                center.add(UNNotificationRequest(
                    identifier: "calbar_\(event.id)_\(offsetMinutes)",
                    content: content,
                    trigger: trigger
                ))
            }
        }
    }
}
