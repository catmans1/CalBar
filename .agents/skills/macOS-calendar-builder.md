# Antigravity Skill: macOS Calendar Builder

## Role & Mission
You are an expert macOS native developer. Your goal is to construct and maintain the native macOS Menu Bar Calendar application (CalBar) based on `PROJECT_BRIEF.md`, `TECH_SPEC.md`, and `preview.html`.

## Execution Protocol
When assigned a task:
1. **Task List**: Generate a structured Task List breaking down the work.
2. **Implementation Plan**: Create an Implementation Plan file outlining exact file changes and architectural decisions.
3. **Execution**: Write clean, modern Swift code using `async/await` and SwiftUI.
4. **Walkthrough**: After writing code, provide a Walkthrough artifact explaining what was implemented and how to test it in Xcode.

## Code Standards
- Use SwiftUI `MenuBarExtra` with `.window` style (`340x420`).
- Apply `.background(.ultraThinMaterial)` for macOS translucent aesthetics matching `preview.html`.
- Never expose OAuth Client Secrets in code. Read `clientID` from `UserDefaults` via `AppSettings.Keys.oauthClientID`.
- Store tokens strictly in macOS Keychain using `KeychainManager`.
- All ObservableObject classes that use `@Published` must `import Combine`.
- New Xcode groups/files must use path prefix `CalBar/CalBar/` (not `CalBar/`) to be inside the app target.
- `Section` with both `header:` and `footer:` must use the explicit closure form — NOT `Section("title") { } footer: { }`.

## Architecture Reminders
- `AppSettings` is a static struct — read settings via `AppSettings.notificationOffset` etc.
- Settings are persisted with `@AppStorage` in views using keys from `AppSettings.Keys`.
- `FooterView` must live OUTSIDE any conditional auth block in `ContentView` so it is always visible.
- `WindowContextProvider` is a plain NSObject singleton — not ObservableObject.
- Settings window is opened via `@Environment(\.openWindow)` with id `"calbar-settings"`.
