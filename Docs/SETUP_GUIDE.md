# Setup Guide — CalBar

## Bước 1: Tạo Google Cloud Project

1. Truy cập [console.cloud.google.com](https://console.cloud.google.com/)
2. Tạo project mới (hoặc chọn project có sẵn)
3. Vào **APIs & Services → Library**
4. Tìm và enable **Google Calendar API**

## Bước 2: Tạo OAuth 2.0 Client ID

1. Vào **APIs & Services → Credentials**
2. Click **+ Create Credentials → OAuth 2.0 Client ID**
3. Application type: **Desktop app**
4. Đặt tên (ví dụ: "CalBar macOS")
5. Click **Create**
6. Copy **Client ID** (dạng: `123456789-abc.apps.googleusercontent.com`)

## Bước 3: Cấu hình Info.plist

Trong Xcode, chọn target **CalBar** → tab **Info** → mục **URL Types** → thêm:

| Field | Giá trị |
|-------|---------|
| Identifier | `com.calbar.oauth` |
| URL Schemes | `com.googleusercontent.apps.123456789-abc` |

> **Lưu ý:** Thay `123456789-abc` bằng phần trước `.apps.googleusercontent.com` trong Client ID của bạn.

## Bước 4: Nhập Client ID vào app

1. Build & Run app trong Xcode
2. Click icon 📅 trên menu bar
3. Click nút **⚙️** ở footer để mở Settings
4. Chọn tab **Tài khoản**
5. Dán Client ID vào ô **OAuth Client ID**

## Bước 5: Đăng nhập

1. Click **Đăng nhập với Google** trong popover
2. Safari/trình duyệt mở ra — đăng nhập tài khoản Google
3. Cấp quyền đọc lịch
4. App tự động load sự kiện hôm nay

## Troubleshooting

| Lỗi | Nguyên nhân | Fix |
|-----|-------------|-----|
| Không mở được browser | URL Scheme chưa đúng trong Info.plist | Kiểm tra scheme khớp với Client ID |
| `invalid_client` | Client ID sai | Kiểm tra lại Client ID trong Settings |
| Không có sự kiện | Chưa chọn lịch | Settings → Lịch → bật lịch muốn hiển thị |
| Token expired | Refresh token hết hạn | Đăng xuất và đăng nhập lại |
