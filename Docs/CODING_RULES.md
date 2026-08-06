# Coding Rules & Lessons Learned

Tài liệu này ghi lại các quy tắc code và lỗi đã gặp trong quá trình phát triển CalBar.

## Swift / SwiftUI Rules

### 1. import Combine bắt buộc cho ObservableObject
Bất kỳ class nào dùng `@Published` phải có `import Combine` — SwiftUI không re-export Combine.
```swift
// ĐÚNG
import Combine
import Foundation

final class MyViewModel: ObservableObject {
    @Published var items: [Item] = []
}
```

### 2. Section với header và footer phải dùng closure form
```swift
// SAI — compiler error
Section("My Header") {
    Toggle(...)
} footer: {
    Text("...")
}

// ĐÚNG
Section {
    Toggle(...)
} header: {
    Text("My Header")
} footer: {
    Text("...")
}
```

### 3. Xcode file path prefix
Khi tạo file/thư mục mới trong Xcode project phải dùng prefix `CalBar/CalBar/` để nằm trong app target:
- ĐÚNG: `CalBar/CalBar/Models/MyModel.swift`
- SAI: `CalBar/Models/MyModel.swift` (nằm ngoài target, không compile)

### 4. WindowContextProvider không phải ObservableObject
```swift
// ĐÚNG — plain NSObject singleton
final class WindowContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = WindowContextProvider()
    private override init() { super.init() }
}
// Dùng @State hoặc singleton, không dùng @StateObject
```

### 5. FooterView phải luôn hiển thị
`FooterView` phải đặt BÊN NGOÀI điều kiện `if auth.isAuthenticated` trong `ContentView`:
```swift
// ĐÚNG
VStack {
    if auth.isAuthenticated { EventList() } else { SignInView() }
    FooterView()  // luôn ở đây
}
```

### 6. Settings Window mở bằng openWindow
```swift
@Environment(\.openWindow) private var openWindow
Button { openWindow(id: "calbar-settings") } label: { ... }
```
Window phải được khai báo trong `CalBarApp.body`:
```swift
Window("Cài đặt", id: "calbar-settings") { SettingsView() }
```

### 7. AppSettings là static struct
```swift
// Đọc settings từ bất kỳ đâu
let offset = AppSettings.notificationOffset
let ids = AppSettings.selectedCalendarIDs

// Views dùng @AppStorage trực tiếp với cùng key
@AppStorage(AppSettings.Keys.notificationOffset) private var offset: Int = 5
```

### 8. AuthManager.clientID đọc từ UserDefaults
clientID không hardcode — đọc từ `UserDefaults` để người dùng có thể cấu hình trong Settings.
redirectScheme được derive tự động từ clientID.
