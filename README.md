# CalBar

A lightweight native macOS Menu Bar app that displays your Google Calendar events for today — right from the status bar.

> Built with **vibe coding** (AI-assisted development using [Claude Code](https://claude.com/claude-code)) for personal use.

---

## What does it do?

CalBar lives quietly in your macOS menu bar. Click the calendar icon to see a compact popover with:

- **All today's events** in a single scrollable list — past events dimmed, upcoming events enabled
- **Auto-scroll** to your next meeting when the popover opens
- **Live countdown** on the next meeting row: `In 2h 3m 15s`, updating every second
- **One-click Join** button for Google Meet links
- **Smart notifications** — local alerts before each event (configurable offset + optional second reminder)
- **Dynamic icon** — menu bar icon switches to a warning badge when a meeting is within 15 minutes
- **Multi-language** — English, Tiếng Việt, 日本語, switchable at runtime

Everything syncs automatically in the background. No browser tab, no Electron, no bloat — pure SwiftUI.

---

## Features

| Feature | Details |
|---|---|
| Menu Bar popover | 340×420, `.ultraThinMaterial` translucent background |
| Authentication | Google OAuth 2.0 + PKCE via `ASWebAuthenticationSession` |
| Token storage | Access + refresh token stored in macOS Keychain |
| Calendar data | Google Calendar REST API v3, supports multiple calendars |
| Event display | Full day list — past events dimmed, next event highlighted with live countdown |
| Auto-scroll | Popover scrolls to next upcoming event on open |
| Notifications | `UNUserNotificationCenter` — configurable offset + optional second reminder |
| Video join | One-click open for Google Meet links |
| Background sync | Auto-refresh every 5 / 15 / 30 min (configurable) |
| Launch at login | `SMAppService` integration |
| Dynamic icon | Warning badge when meeting starts within 15 min |
| Multi-language | English, Tiếng Việt, 日本語 — switchable at runtime |
| Settings window | 6-tab sidebar: Account, Calendars, Notifications, Sync, Display, About |

---

## Requirements

- macOS 13.0 Ventura or later
- Xcode 15+
- A Google account with Google Calendar
- A Google Cloud project with OAuth 2.0 credentials (Desktop app type)

---

## Setup

### 1. Clone the repo

```bash
git clone https://github.com/catmans1/CalBar.git
cd CalBar
open CalBar.xcodeproj
```

### 2. Create a Google OAuth Client

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create or select a project
3. Enable **Google Calendar API**: APIs & Services → Library → search "Google Calendar API" → Enable
4. Create credentials: APIs & Services → Credentials → Create Credentials → OAuth client ID
5. Application type: **Desktop app**
6. Copy the **Client ID** (`123456789-xxxx.apps.googleusercontent.com`) and **Client Secret**

### 3. Configure the URL Scheme in Xcode

Open `CalBar/Info.plist` and set the URL scheme to match your Client ID:

| Key | Value |
|---|---|
| CFBundleURLSchemes | `com.googleusercontent.apps.YOUR_CLIENT_ID` |

> Replace `YOUR_CLIENT_ID` with the numeric portion before `.apps.googleusercontent.com`.
> Example: if your Client ID is `123456-abc.apps.googleusercontent.com`, the scheme is `com.googleusercontent.apps.123456-abc`.

### 4. Build & Run

Select the **CalBar** scheme in Xcode and press `⌘R`.

### 5. Sign in

1. Click the calendar icon in the menu bar → click ⚙️ → **Settings**
2. Go to **Account** tab
3. Paste your **Client ID** and **Client Secret**
4. Click **Sign in with Google** — a browser window opens for OAuth
5. After authorizing, your events load automatically

---

## Project Structure

```
CalBar/
├── CalBarApp.swift              # App entry, MenuBarExtra + Settings Window scenes
├── ContentView.swift            # Popover root — header, event list, footer
├── Models/
│   ├── AppSettings.swift        # UserDefaults accessors, all keys centralized
│   ├── CalendarEvent.swift      # Event model with time formatting
│   ├── CalendarList.swift       # Calendar list API model
│   └── LocalizationManager.swift# Multi-language string tables (en/vi/ja)
├── Services/
│   ├── AuthManager.swift        # OAuth 2.0 + PKCE flow, token refresh
│   ├── GoogleCalendarService.swift # Calendar REST API, concurrent fetch
│   ├── KeychainManager.swift    # Secure token storage
│   └── NotificationManager.swift # UNUserNotificationCenter scheduling
├── ViewModels/
│   └── CalendarViewModel.swift  # @MainActor ObservableObject, business logic
└── Views/
    ├── EventRowView.swift        # Single event row (past/next/future states)
    ├── FooterView.swift          # Notify picker, sync, settings buttons
    ├── NextMeetingCardView.swift # Countdown logic (reusable)
    └── Settings/
        ├── SettingsView.swift
        ├── AccountSettingsView.swift
        ├── CalendarSettingsView.swift
        ├── NotificationSettingsView.swift
        ├── SyncSettingsView.swift
        ├── DisplaySettingsView.swift
        └── AboutSettingsView.swift
```

---

## Tech Stack

- **SwiftUI** — UI, `MenuBarExtra(.window)`, `NavigationSplitView`, `TimelineView`
- **AuthenticationServices** — `ASWebAuthenticationSession` for OAuth
- **CryptoKit** — SHA256 for PKCE code challenge
- **Security** — macOS Keychain for token storage
- **UserNotifications** — local notification scheduling
- **ServiceManagement** — `SMAppService` for launch at login

---

## Vibe Coding

This project was built entirely through **vibe coding** — conversational, AI-assisted development using [Claude Code](https://claude.com/claude-code). The architecture, implementation, multi-language support, and UX improvements were designed and written iteratively through natural-language prompts.

Built for personal use. No App Store distribution planned.

---

## Privacy

- CalBar only requests `calendar.readonly` scope — it cannot modify your calendar
- OAuth tokens are stored locally in your macOS Keychain, never sent to any third-party server
- No analytics, no telemetry

---

## License

Personal use only. Not intended for redistribution or commercial use.
