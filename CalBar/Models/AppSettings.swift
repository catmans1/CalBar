import Foundation

enum CalendarSource: String, CaseIterable, Identifiable {
    case appleCalendar = "appleCalendar"
    case googleDirect = "googleDirect"

    var id: String { rawValue }
    var labelKey: String {
        switch self {
        case .appleCalendar: return "source.appleCalendar"
        case .googleDirect:  return "source.googleDirect"
        }
    }
}

enum MenuBarDisplayMode: String, CaseIterable, Identifiable {
    case iconOnly = "iconOnly"
    case countdown = "countdown"
    case titleAndCountdown = "titleAndCountdown"

    var id: String { rawValue }
    var labelKey: String {
        switch self {
        case .iconOnly: return "menuBar.iconOnly"
        case .countdown: return "menuBar.countdown"
        case .titleAndCountdown: return "menuBar.titleAndCountdown"
        }
    }
}

/// Thin read-only accessor for all UserDefaults-backed settings.
/// Views bind directly with @AppStorage using the same keys.
struct AppSettings {
    private init() {}

    static var calendarSource: CalendarSource {
        get {
            guard let raw = UserDefaults.standard.string(forKey: Keys.calendarSource),
                  let src = CalendarSource(rawValue: raw) else {
                return .appleCalendar
            }
            return src
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: Keys.calendarSource)
        }
    }

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
    static var enableGlobalHotkey: Bool {
        UserDefaults.standard.object(forKey: Keys.enableGlobalHotkey) as? Bool ?? true
    }
    static var menuBarDisplayMode: MenuBarDisplayMode {
        guard let raw = UserDefaults.standard.string(forKey: Keys.menuBarDisplayMode),
              let mode = MenuBarDisplayMode(rawValue: raw) else {
            return .iconOnly
        }
        return mode
    }
    static var oauthClientID: String {
        UserDefaults.standard.string(forKey: Keys.oauthClientID) ?? ""
    }
    static var oauthClientSecret: String {
        UserDefaults.standard.string(forKey: Keys.oauthClientSecret) ?? ""
    }
    static var hasConfiguredCredentials: Bool {
        !oauthClientID.trimmingCharacters(in: .whitespaces).isEmpty &&
        !oauthClientSecret.trimmingCharacters(in: .whitespaces).isEmpty
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
        static let calendarSource          = "calendarDataSource"
        static let enableGlobalHotkey      = "enableGlobalHotkey"
        static let notificationOffset      = "notificationOffsetMinutes"
        static let notificationsEnabled    = "notificationsEnabled"
        static let enableSecondReminder    = "enableSecondReminder"
        static let autoRefreshInterval     = "autoRefreshInterval"
        static let showAllDayEvents        = "showAllDayEvents"
        static let use24HourTime           = "use24HourTime"
        static let maxEventsToShow         = "maxEventsToShow"
        static let showDynamicMenuBarIcon   = "showDynamicMenuBarIcon"
        static let menuBarDisplayMode      = "menuBarDisplayMode"
        static let oauthClientID           = "oauthClientID"
        static let oauthClientSecret       = "oauthClientSecret"
        static let selectedCalendarIDs     = "selectedCalendarIDs"
        static let appLanguage             = "appLanguage"
    }
}
