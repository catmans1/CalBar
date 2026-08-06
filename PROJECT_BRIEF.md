# Project Brief: macOS Menu Bar Google Calendar App

## 1. Project Overview
A lightweight macOS Menu Bar application built natively with Swift and SwiftUI (`MenuBarExtra`). The app connects to the user's Google Calendar account, displays today's scheduled meetings in a translucent popover window, and sends native notifications prior to meeting start times.

## 2. Key Features
1. **Menu Bar Resident**: Resides in the macOS status bar, accessible via single click (`340x420` popover window).
2. **Google OAuth 2.0 Auth**: Authenticate using `ASWebAuthenticationSession` with PKCE. Access & Refresh Tokens stored safely in macOS Keychain.
3. **Calendar Event Synchronization**: Fetch today's events using Google Calendar REST API v3 with automatic 15-minute background refresh.
4. **Next Meeting Highlight**: Prominent gradient card displaying the nearest upcoming meeting with a direct "Join" button for Google Meet/Zoom.
5. **Configurable Notifications**: Schedule `UNUserNotificationCenter` local alerts before N minutes (N ∈ {5, 10, 15, 30} minutes, selectable in UI).
6. **One-Click Video Join**: Clicking a notification or UI button opens the meeting URL (`hangoutLink`) in the default system browser.
7. **Settings Window**: Full settings UI with sidebar navigation — Account, Calendars, Notifications, Sync, Display, About.

## 3. Visual Layout Reference
See `preview.html` for exact UI styling, including translucent dark-mode glassmorphism (`.ultraThinMaterial`), layout padding, and color schemes.
See `preview-settings.html` for the Settings window layout.

## 4. Current Implementation Status
- [x] MenuBarExtra popover (340x420)
- [x] Google OAuth2 + PKCE via ASWebAuthenticationSession
- [x] Keychain token storage
- [x] Google Calendar REST API v3 integration
- [x] Multi-calendar support
- [x] Local notifications (UNUserNotificationCenter)
- [x] Settings window with 6 tabs
- [x] Launch at login (SMAppService)
- [x] Dynamic menu bar icon
