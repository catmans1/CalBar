# Coding Rules & Lessons Learned

Patterns and rules established during CalBar development.

## Swift / SwiftUI

### 1. `import Combine` required for ObservableObject

Any class using `@Published` must import Combine — SwiftUI does not re-export it.

```swift
import Combine
import Foundation

final class MyViewModel: ObservableObject {
    @Published var items: [Item] = []
}
```

### 2. Section with header and footer requires closure form

```swift
// Wrong — compiler error
Section("My Header") {
    Toggle(...)
} footer: { Text("...") }

// Correct
Section {
    Toggle(...)
} header: { Text("My Header") }
  footer: { Text("...") }
```

### 3. Xcode file paths must use `CalBar/CalBar/` prefix

Files must be inside the app target folder to compile:

- Correct: `CalBar/CalBar/Models/MyModel.swift`
- Wrong: `CalBar/Models/MyModel.swift` (outside target, not compiled)

### 4. WindowContextProvider is a plain NSObject, not ObservableObject

```swift
final class WindowContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = WindowContextProvider()
    private override init() { super.init() }
}
```

Use as a singleton directly, not with `@StateObject`.

### 5. FooterView must always be visible

Place `FooterView` outside the `isAuthenticated` condition in `ContentView`:

```swift
VStack {
    if auth.isAuthenticated { EventList() } else { SignInView() }
    FooterView()  // always rendered
}
```

### 6. Settings window opened via openWindow environment action

```swift
@Environment(\.openWindow) private var openWindow
Button { openWindow(id: "calbar-settings") } label: { ... }
```

The `Window` scene must be declared in `CalBarApp.body` with a matching id.

### 7. AppSettings is a static struct — views use @AppStorage with the same keys

```swift
// Read from anywhere
let offset = AppSettings.notificationOffset

// Bind in views
@AppStorage(AppSettings.Keys.notificationOffset) private var offset: Int = 5
```

### 8. Never edit `.pbxproj` while Xcode is open

Editing `project.pbxproj` while Xcode is running risks crashing Xcode or corrupting the project file. Make structural changes (adding files, changing build settings) through Xcode's UI instead.

### 9. Async/await over Combine

All async work uses `async/await` and `Task`. Combine (`Publisher`, `sink`, `AnyCancellable`) is not used in this project.

### 10. Google OAuth for Desktop apps requires client_secret

Desktop-type OAuth clients require `client_secret` in both the authorization code exchange and token refresh requests, even when using PKCE.

### 11. App Sandbox blocks all outgoing network by default

The `com.apple.security.network.client` entitlement must be set to `true` in the `.entitlements` file for any outgoing HTTP request to succeed.
