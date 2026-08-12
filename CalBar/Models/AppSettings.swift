import Foundation

/// Thin read-only accessor for all UserDefaults-backed settings.
/// Views bind directly with @AppStorage using the same keys.
struct AppSettings {
    private init() {}

    static var notificationOffset: Int {
        let v = UserDefaults.standard.integer(forKey: Keys.notificationOffset)
        return v == 0 ? 5 : v
    }
    static var notificationsEnabled: Bool {
        UserDefaults.standard.object(forKey: Keys.notificationsEnabled) as? Bool ?? true
    }
    static var enableSecondReminder: Bool {
        UserDefaults.standard.bool(forKey: Keys.enableSecondReminder)
    }
    static var autoRefreshMinutes: Int {
        let v = UserDefaults.standard.integer(forKey: Keys.autoRefreshInterval)
        return v == 0 ? 15 : v
    }
    static var showAllDayEvents: Bool {
        UserDefaults.standard.bool(forKey: Keys.showAllDayEvents)
    }
    static var use24HourTime: Bool {
        UserDefaults.standard.object(forKey: Keys.use24HourTime) as? Bool ?? true
    }
    static var maxEventsToShow: Int {
        let v = UserDefaults.standard.integer(forKey: Keys.maxEventsToShow)
        return v == 0 ? 5 : v
    }
    static var showDynamicMenuBarIcon: Bool {
        UserDefaults.standard.object(forKey: Keys.showDynamicMenuBarIcon) as? Bool ?? true
    }
    static var oauthClientID: String {
        UserDefaults.standard.string(forKey: Keys.oauthClientID) ?? ""
    }
    static var selectedCalendarIDs: Set<String> {
        get {
            guard let data = UserDefaults.standard.data(forKey: Keys.selectedCalendarIDs),
                  let arr = try? JSONDecoder().decode([String].self, from: data)
            else { return [] }
            return Set(arr)
        }
        set {
            let data = try? JSONEncoder().encode(Array(newValue))
            UserDefaults.standard.set(data, forKey: Keys.selectedCalendarIDs)
        }
    }

    enum Keys {
        static let notificationOffset    = "notificationOffsetMinutes"
        static let notificationsEnabled  = "notificationsEnabled"
        static let enableSecondReminder  = "enableSecondReminder"
        static let autoRefreshInterval   = "autoRefreshInterval"
        static let showAllDayEvents      = "showAllDayEvents"
        static let use24HourTime         = "use24HourTime"
        static let maxEventsToShow       = "maxEventsToShow"
        static let showDynamicMenuBarIcon = "showDynamicMenuBarIcon"
        static let oauthClientID         = "oauthClientID"
        static let oauthClientSecret     = "oauthClientSecret"
        static let selectedCalendarIDs   = "selectedCalendarIDs"
        static let appLanguage           = "appLanguage"
    }
}
