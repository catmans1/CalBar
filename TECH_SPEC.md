# Technical Specification — CalBar

## 1. System Requirements
- Platform: macOS 13.0 (Ventura) or later
- Swift Version: Swift 5.8+
- Frameworks: SwiftUI (`MenuBarExtra`), AppKit, UserNotifications, Security, AuthenticationServices, CryptoKit, ServiceManagement.

## 2. Architecture & Modules

### A. Data Models (`Models/`)
- `CalendarEvent` — id, summary, start, end, hangoutLink?, location?, isAllDay
- `AppSettings` — static struct reading UserDefaults (all settings keys centralized in `Keys` enum)
- `CalendarList` — `CalendarListResponse`, `CalendarListItem`, `Color(hex:)` extension

### B. Authentication (`Services/AuthManager.swift`)
- Flow: OAuth 2.0 with PKCE via `ASWebAuthenticationSession`
- Scope: `https://www.googleapis.com/auth/calendar.readonly email profile`
- Storage: Refresh Token + Access Token + Expiry + Email in macOS Keychain (`KeychainManager.swift`)
- clientID: read from UserDefaults key `oauthClientID` (configurable in Settings)
- redirectScheme: derived automatically from clientID

### C. Google Calendar Service (`Services/GoogleCalendarService.swift`)
- `fetchCalendarList()` → `GET /users/me/calendarList`
- `fetchTodayEvents()` → fetches from all `AppSettings.selectedCalendarIDs` concurrently via `withThrowingTaskGroup`
- Token refresh: intercept HTTP 401 and retry once with fresh token

### D. Notification Manager (`Services/NotificationManager.swift`)
- Framework: `UserNotifications` (`UNUserNotificationCenter`)
- Trigger Time = event.start − (offsetMinutes × 60)
- Supports optional second reminder at 1 minute before

### E. ViewModel (`ViewModels/CalendarViewModel.swift`)
- `@MainActor` ObservableObject
- Respects: maxEventsToShow, showAllDayEvents, autoRefreshMinutes, notificationsEnabled
- `menuBarIconName` — returns `calendar.badge.exclamationmark` when meeting ≤15 min away

### F. Settings (`Views/Settings/`)
- `SettingsView` — NavigationSplitView sidebar, opened via `Window` scene id `"calbar-settings"`
- Tabs: Account, Calendars, Notifications, Sync, Display, About
- All settings persist via `@AppStorage` to UserDefaults

## 3. Project Structure
```
CalBar/
├── Models/
│   ├── CalendarEvent.swift
│   ├── CalendarList.swift
│   └── AppSettings.swift
├── Services/
│   ├── AuthManager.swift
│   ├── GoogleCalendarService.swift
│   ├── KeychainManager.swift
│   └── NotificationManager.swift
├── ViewModels/
│   └── CalendarViewModel.swift
├── Views/
│   ├── Settings/
│   │   ├── SettingsView.swift
│   │   ├── AccountSettingsView.swift
│   │   ├── CalendarSettingsView.swift
│   │   ├── NotificationSettingsView.swift
│   │   ├── SyncSettingsView.swift
│   │   ├── DisplaySettingsView.swift
│   │   └── AboutSettingsView.swift
│   ├── NextMeetingCardView.swift
│   ├── EventRowView.swift
│   └── FooterView.swift
├── ContentView.swift
└── CalBarApp.swift
```

## 4. UserDefaults Keys (AppSettings.Keys)
| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `notificationOffsetMinutes` | Int | 5 | Minutes before event to notify |
| `notificationsEnabled` | Bool | true | Toggle notifications on/off |
| `enableSecondReminder` | Bool | false | Second reminder 1 min before |
| `autoRefreshInterval` | Int | 15 | Background sync interval (min) |
| `showAllDayEvents` | Bool | false | Show all-day events in list |
| `use24HourTime` | Bool | true | 24h vs 12h time format |
| `maxEventsToShow` | Int | 5 | Max events shown in popover |
| `showDynamicMenuBarIcon` | Bool | true | Dynamic icon when meeting soon |
| `oauthClientID` | String | "" | Google OAuth Client ID |
| `selectedCalendarIDs` | Data | [] | JSON-encoded [String] of calendar IDs |

## 5. Setup Instructions
1. Create a Google Cloud project, enable Google Calendar API
2. Create OAuth 2.0 Desktop app client → copy Client ID
3. In Settings → Tài khoản → paste Client ID
4. Add URL Scheme to Info.plist:
   - Identifier: `com.calbar.oauth`
   - URL Scheme: `com.googleusercontent.apps.YOUR_CLIENT_ID`
5. Build and run — click Sign In
