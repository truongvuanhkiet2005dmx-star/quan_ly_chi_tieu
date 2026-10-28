# SmartMoney v2 - Quản Lý Chi Tiêu (Flutter Frontend)

Ứng dụng quản lý tài chính cá nhân thông minh với khả năng tự động bóc tách thông báo ngân hàng/SMS, quét hóa đơn AI camera và nhập giao dịch bằng giọng nói Tiếng Việt.

---

## 🛠️ Yêu Cầu Cấu Hình Môi Trường (System Requirements)

* **Flutter SDK**: `>= 3.24.0` (Khuyến nghị `3.27.0` trở lên)
* **Dart SDK**: `>= 3.5.0`
* **Android Studio**: Android SDK 34/35, Java 17

---

## 🚀 Hướng Dẫn Chạy Ứng Dụng (Getting Started)

1. **Cài đặt dependencies**:
   ```bash
   flutter pub get
   ```

2. **Cấu hình Firebase**:
   Đặt tệp `google-services.json` tải từ Firebase Console vào đường dẫn:
   `android/app/google-services.json`

3. **Khởi chạy trên Android Emulator / Thiết bị thật**:
   ```bash
   flutter run
   ```

---

## 📋 Chính Sách Google Play Store (Google Play Permissions Declaration)

Ứng dụng yêu cầu các quyền nhạy cảm `android.permission.RECEIVE_SMS` và `android.permission.READ_SMS` nhằm phục vụ trực tiếp cho tính năng **Tự động trích xuất biến động số dư tài khoản ngân hàng để quản lý chi tiêu (Core Feature: Financial & Budgeting Management)**.

* **Sử dụng dữ liệu**: Dữ liệu tin nhắn chỉ được phân tích xử lý cục bộ On-Device (trên thiết bị của người dùng) để ghi nhận thu chi.
* **Bảo mật**: Tuyệt đối không gửi hay chia sẻ nội dung tin nhắn rác hoặc thông tin nhạy cảm của người dùng ra bên ngoài.
