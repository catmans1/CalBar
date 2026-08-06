# CalBar

A lightweight native macOS Menu Bar app that displays your Google Calendar events for today — right from the status bar.

> 🤖 **Built with vibe coding** (AI-assisted development using Claude Code) for personal use.

---

## What does it do?

CalBar lives quietly in your macOS menu bar. Click the calendar icon to see a compact 340×420 popover with:

- **Next meeting card** — highlighted gradient card showing your nearest upcoming event, with a one-click **Join Meet** button
- **Today's events** — full list of today's remaining meetings with time and location
- **Smart notifications** — local alerts sent 5, 10, 15, or 30 minutes before each event
- **Dynamic icon** — menu bar icon switches to a warning badge when a meeting is within 15 minutes

Everything syncs automatically every 15 minutes in the background. No browser tab, no Electron, no bloat — pure SwiftUI.

---

## Features

| Feature | Details |
|---|---|
| Menu Bar popover | 340×420, `.ultraThinMaterial` translucent background |
| Authentication | Google OAuth 2.0 + PKCE via `ASWebAuthenticationSession` |
| Token storage | Access token + refresh token stored in macOS Keychain |
| Calendar data | Google Calendar REST API v3, supports multiple calendars |
| Notifications | `UNUserNotificationCenter` — configurable offset + optional second reminder |
| Video join | One-click open for Google Meet links |
| Background sync | Auto-refresh every 5 / 15 / 30 min (configurable) |
| Launch at login | `SMAppService` integration |
| Dynamic icon | ⚠️ badge when meeting starts within 15 min |
| Multi-language | English, Tiếng Việt, 日本語 — switchable at runtime |
| Settings window | 6-tab sidebar: Account, Calendars, Notifications, Sync, Display, About |

---

## Requirements

- macOS 13.0 Ventura or later
- Xcode 15+
- A Google account with Google Calendar
- A Google Cloud project with OAuth 2.0 credentials

---

## Setup

### 1. Clone the repo

```bash
git clone https://github.com/catmans1/CalBar.git
cd CalBar
open CalBar.xcodeproj
```

### 2. Create a Google OAuth Client ID

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project (or select an existing one)
3. Enable **Google Calendar API**: *APIs & Services → Library → search "Google Calendar API" → Enable*
4. Create credentials: *APIs & Services → Credentials → Create Credentials → OAuth client ID*
5. Application type: **Desktop app**
6. Copy the generated **Client ID** — it looks like `123456789-xxxx.apps.googleusercontent.com`

### 3. Add URL Scheme to Xcode

In Xcode, open `CalBar/Info.plist` and add a URL Scheme entry:

| Key | Value |
|---|---|
| URL Schemes | `com.googleusercontent.apps.YOUR_CLIENT_ID` |

> Replace `YOUR_CLIENT_ID` with the numeric part before `.apps.googleusercontent.com`. For example, if your Client ID is `123456-abc.apps.googleusercontent.com`, the scheme is `com.googleusercontent.apps.123456-abc`.

### 4. Build & Run

- Select the **CalBar** scheme in Xcode
- Press `⌘R` to build and run
- The calendar icon appears in your menu bar

### 5. Sign in

1. Click the menu bar icon → click the ⚙️ button → **Settings**
2. Go to **Account** tab → paste your Client ID
3. Click **Sign in with Google** — a browser window will open for OAuth
4. After authorizing, your events will load automatically

---

## Project Structure

```
CalBar/
├── CalBarApp.swift              # App entry, MenuBarExtra + Settings Window scenes
├── ContentView.swift            # Popover root — header, event list, footer
├── Models/
│   ├── AppSettings.swift        # UserDefaults accessors, all keys centralized
│   ├── CalendarEvent.swift      # Event model with time formatting
│   ├── CalendarList.swift       # Calendar list API model + Color(hex:)
│   └── LocalizationManager.swift# Multi-language (en/vi/ja) string tables
├── Services/
│   ├── AuthManager.swift        # OAuth 2.0 + PKCE flow
│   ├── GoogleCalendarService.swift # Calendar REST API, concurrent fetch
│   ├── KeychainManager.swift    # Secure token storage
│   └── NotificationManager.swift # UNUserNotificationCenter scheduling
├── ViewModels/
│   └── CalendarViewModel.swift  # @MainActor ObservableObject, business logic
└── Views/
    ├── NextMeetingCardView.swift # Gradient card for upcoming meeting
    ├── EventRowView.swift        # Single event row
    ├── FooterView.swift          # Notify picker, sync, settings, sign-out
    └── Settings/
        ├── SettingsView.swift    # NavigationSplitView sidebar
        ├── AccountSettingsView.swift
        ├── CalendarSettingsView.swift
        ├── NotificationSettingsView.swift
        ├── SyncSettingsView.swift
        ├── DisplaySettingsView.swift
        └── AboutSettingsView.swift
```

---

## Tech Stack

- **SwiftUI** — UI, `MenuBarExtra(.window)`, `NavigationSplitView`
- **AuthenticationServices** — `ASWebAuthenticationSession` for OAuth
- **CryptoKit** — SHA256 for PKCE code challenge
- **Security** — macOS Keychain for token storage
- **UserNotifications** — local notification scheduling
- **ServiceManagement** — `SMAppService` for launch at login

---

## Vibe Coding

This project was built entirely through **vibe coding** — conversational, AI-assisted development using [Claude Code](https://claude.com/claude-code). The architecture, implementation, and multi-language support were designed and written iteratively through natural-language prompts.

Built for personal use. No App Store distribution planned.

---

## Privacy

- CalBar only requests `calendar.readonly` scope — it cannot modify your calendar
- OAuth tokens are stored locally in your macOS Keychain, never sent to any third-party server
- No analytics, no telemetry

---

## License

Personal use only. Not intended for redistribution or commercial use.
