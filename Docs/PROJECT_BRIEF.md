# Project Brief: CalBar — macOS Menu Bar Google Calendar App

## 1. Overview

A lightweight macOS Menu Bar application built natively with Swift and SwiftUI (`MenuBarExtra`). The app connects to a Google Calendar account, displays today's events in a translucent popover, and sends native notifications before meeting start times.

## 2. Features

| # | Feature | Details |
|---|---|---|
| 1 | Menu Bar resident | 340×420 popover, `.ultraThinMaterial` background |
| 2 | Google OAuth 2.0 | PKCE flow via `ASWebAuthenticationSession`, tokens in Keychain |
| 3 | Event display | Full day list — past events dimmed, next event highlighted with live countdown |
| 4 | Auto-scroll | Scrolls to next upcoming event on popover open |
| 5 | Live countdown | h/m/s countdown on next meeting row, updates every second via `TimelineView` |
| 6 | Multi-calendar | Concurrent fetch from selected calendars |
| 7 | Notifications | `UNUserNotificationCenter`, configurable offset (5/10/15/30 min) + second reminder |
| 8 | Video join | One-click open for Google Meet links |
| 9 | Background sync | Auto-refresh every 5/15/30 min |
| 10 | Launch at login | `SMAppService` |
| 11 | Dynamic icon | Warning badge within 15 min of meeting |
| 12 | Multi-language | English, Tiếng Việt, 日本語 — switchable at runtime |
| 13 | Settings | 6-tab sidebar: Account, Calendars, Notifications, Sync, Display, About |

## 3. Implementation Status

- [x] MenuBarExtra popover (340×420)
- [x] Google OAuth 2.0 + PKCE via ASWebAuthenticationSession
- [x] Client Secret support for Desktop app OAuth flow
- [x] Keychain token storage
- [x] Google Calendar REST API v3 integration
- [x] Multi-calendar support
- [x] Flat event list with past/next/future visual states
- [x] Auto-scroll to next upcoming event
- [x] Live h/m/s countdown badge via TimelineView
- [x] Local notifications (UNUserNotificationCenter)
- [x] Settings window with 6 tabs
- [x] Launch at login (SMAppService)
- [x] Dynamic menu bar icon
- [x] Multi-language: English, Vietnamese, Japanese

## 4. Architecture

MVVM with a dedicated Services layer:

- **Models** — pure data structs (`CalendarEvent`, `AppSettings`, `CalendarList`, `LocalizationManager`)
- **Services** — I/O layer (`AuthManager`, `GoogleCalendarService`, `KeychainManager`, `NotificationManager`)
- **ViewModel** — `CalendarViewModel` (`@MainActor ObservableObject`), business logic and state
- **Views** — SwiftUI views bound to ViewModel via `@EnvironmentObject`
