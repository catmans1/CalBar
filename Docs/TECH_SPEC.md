# Technical Specification — CalBar

## 1. System Requirements

- Platform: macOS 13.0 (Ventura) or later
- Swift 5.8+
- Frameworks: SwiftUI, AppKit, UserNotifications, Security, AuthenticationServices, CryptoKit, ServiceManagement

## 2. Architecture

MVVM + Services layer. No Combine — all async work uses `async/await`.

### Models (`Models/`)

| File | Purpose |
|---|---|
| `CalendarEvent.swift` | Event struct: id, summary, start, end, hangoutLink?, location?, isAllDay. Conforms to `Identifiable, Codable, Equatable` |
| `AppSettings.swift` | Static struct reading UserDefaults; all keys centralized in `AppSettings.Keys` |
| `CalendarList.swift` | API response models for calendar list; `Color(hex:)` extension |
| `LocalizationManager.swift` | `@MainActor ObservableObject`; runtime language switching (en/vi/ja); `str(_:)` and `strFormatStr(_:_:)` helpers |

### Services (`Services/`)

**`AuthManager.swift`**
- OAuth 2.0 + PKCE via `ASWebAuthenticationSession`
- Scope: `calendar.readonly email profile`
- clientID and clientSecret read from UserDefaults (configurable in Settings)
- redirectScheme derived automatically from clientID
- Tokens stored in Keychain: access token, refresh token, expiry, email
- Error surfacing: decodes Google error JSON before attempting TokenResponse decode

**`GoogleCalendarService.swift`**
- `fetchCalendarList()` → `GET /users/me/calendarList`
- `fetchTodayEvents()` → concurrent fetch from all `selectedCalendarIDs` via `withThrowingTaskGroup`
- Token refresh: intercept HTTP 401, retry once with fresh token

**`KeychainManager.swift`**
- Wraps Security framework for Keychain read/write/delete
- Keys: accessToken, refreshToken, tokenExpiry, userEmail

**`NotificationManager.swift`**
- `UNUserNotificationCenter` scheduling
- Trigger = `event.start − offsetMinutes`
- Optional second reminder at 1 minute before

### ViewModel (`ViewModels/CalendarViewModel.swift`)

`@MainActor ObservableObject`

| Property | Description |
|---|---|
| `events` | All today's events from API |
| `todayEvents` | Filtered/sorted: respects showAllDayEvents, capped at maxEventsToShow for future events |
| `nextMeeting` | First event where `end > Date() && !isAllDay` |
| `upcomingEvents` | `todayEvents` filtered to future only (used for empty-state check) |
| `menuBarIconName` | `calendar.badge.exclamationmark` when next meeting ≤ 15 min away |

### Views (`Views/`)

**`ContentView.swift`**
- `ScrollViewReader` wraps the event list; auto-scrolls to `nextMeeting.id` on appear and on events change
- Three row states passed to `EventRowView`: `isPast`, `isNext`, default

**`EventRowView.swift`**
- `isPast`: dimmed text, no Join button, faint background
- `isNext`: blue accent bar, semibold title, blue-tinted background, live countdown via `TimelineView(.periodic(from: .now, by: 1))`
- Default: normal styling

**`NextMeetingCardView.swift`**
- Contains countdown formatting logic (h/m/s), kept for reuse

**`FooterView.swift`**
- Notification offset picker, sync button, settings button, sign-out

**`Settings/`**
- `SettingsView`: `NavigationSplitView` sidebar, opened via `Window` scene id `"calbar-settings"`
- `AccountSettingsView`: Client ID, Client Secret, sign-in/out, test connection (shows HTTP status code on failure)

## 3. Project Structure

```
CalBar/CalBar/
├── Models/
│   ├── AppSettings.swift
│   ├── CalendarEvent.swift
│   ├── CalendarList.swift
│   └── LocalizationManager.swift
├── Services/
│   ├── AuthManager.swift
│   ├── GoogleCalendarService.swift
│   ├── KeychainManager.swift
│   └── NotificationManager.swift
├── ViewModels/
│   └── CalendarViewModel.swift
├── Views/
│   ├── EventRowView.swift
│   ├── FooterView.swift
│   ├── NextMeetingCardView.swift
│   └── Settings/
│       ├── SettingsView.swift
│       ├── AccountSettingsView.swift
│       ├── CalendarSettingsView.swift
│       ├── NotificationSettingsView.swift
│       ├── SyncSettingsView.swift
│       ├── DisplaySettingsView.swift
│       └── AboutSettingsView.swift
├── ContentView.swift
├── CalBarApp.swift
├── CalBar.entitlements
└── Info.plist
```

## 4. UserDefaults Keys (`AppSettings.Keys`)

| Key | Type | Default | Description |
|---|---|---|---|
| `notificationOffsetMinutes` | Int | 5 | Minutes before event to notify |
| `notificationsEnabled` | Bool | true | Enable/disable notifications |
| `enableSecondReminder` | Bool | false | Second reminder 1 min before |
| `autoRefreshInterval` | Int | 15 | Background sync interval (min) |
| `showAllDayEvents` | Bool | false | Show all-day events in list |
| `use24HourTime` | Bool | true | 24h vs 12h time format |
| `maxEventsToShow` | Int | 5 | Max future events shown |
| `showDynamicMenuBarIcon` | Bool | true | Dynamic icon when meeting soon |
| `oauthClientID` | String | "" | Google OAuth Client ID |
| `oauthClientSecret` | String | "" | Google OAuth Client Secret |
| `selectedCalendarIDs` | Data | [] | JSON-encoded [String] of calendar IDs |
| `appLanguage` | String | "system" | Language: "system", "en", "vi", "ja" |

## 5. Entitlements (`CalBar.entitlements`)

| Key | Value | Reason |
|---|---|---|
| `com.apple.security.app-sandbox` | true | Required for Mac App Store / distribution |
| `com.apple.security.network.client` | true | Required for all outgoing HTTP (OAuth, Calendar API) |
