import Combine
import Foundation

final class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    @Published var language: String {
        didSet { UserDefaults.standard.set(language, forKey: AppSettings.Keys.appLanguage) }
    }

    private init() {
        language = UserDefaults.standard.string(forKey: AppSettings.Keys.appLanguage) ?? "system"
    }

    private var resolved: String {
        guard language != "system" else {
            let code = Locale.current.language.languageCode?.identifier ?? "en"
            return ["en", "vi", "ja"].contains(code) ? code : "en"
        }
        return language
    }

    func str(_ key: String) -> String {
        Strings.all[resolved]?[key] ?? Strings.all["en"]?[key] ?? key
    }

    func strFormat(_ key: String, _ n: Int) -> String {
        String(format: str(key), n)
    }

    func strFormatStr(_ key: String, _ s: String) -> String {
        String(format: str(key), s)
    }
}

// MARK: - String Tables

private enum Strings {
    static let all: [String: [String: String]] = ["en": en, "vi": vi, "ja": ja]

    static let en: [String: String] = [
        "app.title": "Google Calendar",
        "settings.title": "CalBar Settings",
        "today": "Today",
        "events.empty": "No more events today",
        "signin.description": "Sign in to view your calendar events",
        "signin.button": "Sign in with Google",
        "notify.before": "Notify:",
        "time.5m": "5 min", "time.10m": "10 min", "time.15m": "15 min", "time.30m": "30 min",
        "sync.now": "Sync",
        "settings": "Settings",
        "sign.out": "Sign out",
        "meeting.now": "Happening now",
        "meeting.inMinute": "In 1 minute",
        "meeting.inMinutes": "In %d minutes",
        "meeting.inDuration": "In %@",
        "meeting.join": "Join Meet",
        "join": "Join",
        "tab.account": "Account",
        "tab.calendars": "Calendars",
        "tab.notifications": "Notifications",
        "tab.sync": "Sync",
        "tab.display": "Display",
        "tab.about": "About",
        "account.google": "Google Account",
        "account.connected": "Connected",
        "account.oauthConfig": "Google API (OAuth 2.0)",
        "account.testConn": "Test connection",
        "account.oauthFooter": "Create a Desktop OAuth Client in Google Cloud Console → APIs & Services → Credentials.",
        "success": "Success",
        "error.http": "HTTP Error",
        "calendars.header": "Displayed Calendars",
        "calendars.primary": "Primary",
        "calendars.empty": "Please sign in to view your calendars.",
        "calendars.footer": "Only enabled calendars appear in the popover.",
        "refresh": "Refresh",
        "notif.enable": "Enable event notifications",
        "notif.before": "Notify before",
        "notif.secondReminder": "Second reminder (1 min before)",
        "notif.header": "Notifications",
        "notif.footer": "A second reminder is sent 1 minute before the event starts.",
        "sync.auto": "Auto sync",
        "sync.interval": "Refresh interval",
        "sync.launchAtLogin": "Launch at login",
        "sync.showAllDay": "Show all-day events",
        "sync.footer": "'Launch at login' requires the app to be installed in /Applications.",
        "off": "Off",
        "system": "System",
        "display.eventList": "Event list",
        "display.timeFormat": "Time format",
        "display.24h": "24-hour — 18:30",
        "display.12h": "12-hour — 6:30 PM",
        "display.maxEvents": "Max events: %d",
        "display.dynamicIcon": "Dynamic icon when meeting soon",
        "display.dynamicIconFooter": "Icon changes to ⚠️ within 15 minutes of a meeting.",
        "display.language": "Language",
        "display.languageSystem": "System (follows device)",
        "about.subtitle": "macOS Menu Bar Google Calendar",
        "about.info": "Information",
        "about.version": "Version",
        "about.requirements": "Requirements",
        "about.integration": "Integration",
        "about.tokenStorage": "Token storage",
        "about.macosReq": "macOS 13.0 Ventura or later",
        "about.keychain": "macOS Keychain",
    ]

    static let vi: [String: String] = [
        "app.title": "Google Calendar",
        "settings.title": "Cài đặt CalBar",
        "today": "Hôm nay",
        "events.empty": "Không còn sự kiện nào hôm nay",
        "signin.description": "Đăng nhập để xem lịch của bạn",
        "signin.button": "Đăng nhập với Google",
        "notify.before": "Báo trước:",
        "time.5m": "5 phút", "time.10m": "10 phút", "time.15m": "15 phút", "time.30m": "30 phút",
        "sync.now": "Đồng bộ",
        "settings": "Cài đặt",
        "sign.out": "Đăng xuất",
        "meeting.now": "Đang diễn ra",
        "meeting.inMinute": "Trong 1 phút nữa",
        "meeting.inMinutes": "Trong %d phút nữa",
        "meeting.inDuration": "Còn %@",
        "meeting.join": "Vào Meet",
        "join": "Tham gia",
        "tab.account": "Tài khoản",
        "tab.calendars": "Lịch",
        "tab.notifications": "Thông báo",
        "tab.sync": "Đồng bộ",
        "tab.display": "Giao diện",
        "tab.about": "Giới thiệu",
        "account.google": "Tài khoản Google",
        "account.connected": "Đã kết nối",
        "account.oauthConfig": "Google API (OAuth 2.0)",
        "account.testConn": "Kiểm tra kết nối",
        "account.oauthFooter": "Tạo Desktop OAuth Client tại Google Cloud Console → APIs & Services → Credentials.",
        "success": "Thành công",
        "error.http": "Lỗi HTTP",
        "calendars.header": "Lịch hiển thị",
        "calendars.primary": "Chính",
        "calendars.empty": "Vui lòng đăng nhập để xem danh sách lịch.",
        "calendars.footer": "Chỉ những lịch được bật mới xuất hiện trong popover.",
        "refresh": "Làm mới",
        "notif.enable": "Bật thông báo sự kiện",
        "notif.before": "Báo trước",
        "notif.secondReminder": "Nhắc lại lần 2 (1 phút trước)",
        "notif.header": "Thông báo",
        "notif.footer": "Nhắc lần 2 sẽ được gửi 1 phút trước giờ bắt đầu.",
        "sync.auto": "Tự động đồng bộ",
        "sync.interval": "Chu kỳ làm mới",
        "sync.launchAtLogin": "Khởi động cùng macOS",
        "sync.showAllDay": "Hiển thị sự kiện cả ngày",
        "sync.footer": "'Khởi động cùng macOS' yêu cầu app được cài trong /Applications.",
        "off": "Tắt",
        "system": "Hệ thống",
        "display.eventList": "Danh sách sự kiện",
        "display.timeFormat": "Định dạng giờ",
        "display.24h": "24 giờ — 18:30",
        "display.12h": "12 giờ — 6:30 PM",
        "display.maxEvents": "Số sự kiện tối đa: %d",
        "display.dynamicIcon": "Icon động khi sắp có cuộc họp",
        "display.dynamicIconFooter": "Icon đổi sang ⚠️ trong vòng 15 phút trước cuộc họp.",
        "display.language": "Ngôn ngữ",
        "display.languageSystem": "Hệ thống (theo thiết bị)",
        "about.subtitle": "macOS Menu Bar Google Calendar",
        "about.info": "Thông tin",
        "about.version": "Phiên bản",
        "about.requirements": "macOS yêu cầu",
        "about.integration": "Tích hợp",
        "about.tokenStorage": "Lưu trữ token",
        "about.macosReq": "macOS 13.0 Ventura trở lên",
        "about.keychain": "macOS Keychain",
    ]

    static let ja: [String: String] = [
        "app.title": "Google Calendar",
        "settings.title": "CalBar 設定",
        "today": "今日",
        "events.empty": "今日のイベントはありません",
        "signin.description": "カレンダーを表示するにはサインインしてください",
        "signin.button": "Googleでサインイン",
        "notify.before": "通知タイミング:",
        "time.5m": "5分", "time.10m": "10分", "time.15m": "15分", "time.30m": "30分",
        "sync.now": "同期",
        "settings": "設定",
        "sign.out": "サインアウト",
        "meeting.now": "開催中",
        "meeting.inMinute": "1分後",
        "meeting.inMinutes": "%d分後",
        "meeting.inDuration": "%@後",
        "meeting.join": "Meetに参加",
        "join": "参加",
        "tab.account": "アカウント",
        "tab.calendars": "カレンダー",
        "tab.notifications": "通知",
        "tab.sync": "同期",
        "tab.display": "表示",
        "tab.about": "情報",
        "account.google": "Googleアカウント",
        "account.connected": "接続済み",
        "account.oauthConfig": "Google API (OAuth 2.0)",
        "account.testConn": "接続テスト",
        "account.oauthFooter": "Google Cloud Console → APIs & Services → Credentials でデスクトップ OAuth クライアントを作成してください。",
        "success": "成功",
        "error.http": "HTTPエラー",
        "calendars.header": "表示するカレンダー",
        "calendars.primary": "メイン",
        "calendars.empty": "カレンダーを表示するにはサインインしてください。",
        "calendars.footer": "有効にしたカレンダーのみポップオーバーに表示されます。",
        "refresh": "更新",
        "notif.enable": "イベント通知を有効にする",
        "notif.before": "事前通知",
        "notif.secondReminder": "2回目のリマインダー（1分前）",
        "notif.header": "通知",
        "notif.footer": "2回目のリマインダーはイベント開始1分前に送信されます。",
        "sync.auto": "自動同期",
        "sync.interval": "更新間隔",
        "sync.launchAtLogin": "ログイン時に起動",
        "sync.showAllDay": "終日イベントを表示",
        "sync.footer": "「ログイン時に起動」はアプリが /Applications にインストールされている必要があります。",
        "off": "オフ",
        "system": "システム",
        "display.eventList": "イベントリスト",
        "display.timeFormat": "時刻形式",
        "display.24h": "24時間 — 18:30",
        "display.12h": "12時間 — 6:30 PM",
        "display.maxEvents": "最大表示数: %d",
        "display.dynamicIcon": "会議が近い時にアイコンを変更",
        "display.dynamicIconFooter": "会議の15分前にアイコンが⚠️に変わります。",
        "display.language": "言語",
        "display.languageSystem": "システム（デバイスに従う）",
        "about.subtitle": "macOS メニューバー Google カレンダー",
        "about.info": "情報",
        "about.version": "バージョン",
        "about.requirements": "動作環境",
        "about.integration": "連携",
        "about.tokenStorage": "トークン保存",
        "about.macosReq": "macOS 13.0 Ventura 以降",
        "about.keychain": "macOS キーチェーン",
    ]
}
