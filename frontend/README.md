# SmartMoney v2 - Quản Lý Chi Tiêu (Flutter Frontend)

Ứng dụng quản lý tài chính cá nhân thông minh với khả năng tự động bóc tách thông báo ngân hàng/SMS, quét hóa đơn AI camera và nhập giao dịch bằng giọng nói Tiếng Việt.

---

## 🛠️ Yêu Cầu Cấu Hình Môi Trường (System Requirements)

* **Flutter SDK**: `>= 3.0.0`
* **Dart SDK**: `>= 3.0.0 < 4.0.0`
* **Android SDK**: `compileSdk = 34`, `targetSdk = 34` (Android 14/15)

---

## 🚀 Hướng Dẫn Chạy Trên Android Emulator & Điện Thoại Thật (Real Physical Device)

1. **Cài đặt dependencies**:
   ```bash
   flutter pub get
   ```

2. **Cấu hình Firebase**:
   Đặt tệp `google-services.json` tải từ Firebase Console vào đường dẫn:
   `android/app/google-services.json`

3. **Chạy trên Android Emulator (Cổng mặc định 10.0.2.2)**:
   ```bash
   flutter run
   ```

4. **Chạy trên Điện thoại thật (Physical Device) qua Mạng Wifi / IP LAN**:
   > [!IMPORTANT]
   > Điện thoại thật không thể sử dụng IP `10.0.2.2`. Bạn cần truyền IP LAN máy tính đang bật Backend C# bằng cờ `--dart-define`:
   ```bash
   flutter run --dart-define=BACKEND_URL=http://<IP_MÁY_TÍNH_CỦA_BẠN>:5104/api/transactions
   ```
   *(Ví dụ: `flutter run --dart-define=BACKEND_URL=http://192.168.1.15:5104/api/transactions`)*

---

## 📋 Chính Sách Google Play Store (Google Play Permissions Declaration)

Ứng dụng yêu cầu các quyền nhạy cảm `android.permission.RECEIVE_SMS` và `android.permission.READ_SMS` nhằm phục vụ trực tiếp cho tính năng **Tự động trích xuất biến động số dư tài khoản ngân hàng để quản lý chi tiêu (Core Feature: Financial & Budgeting Management)**.

* **Sử dụng dữ liệu**: Dữ liệu tin nhắn chỉ được phân tích xử lý cục bộ On-Device (trên thiết bị của người dùng) để ghi nhận thu chi.
* **Bảo mật**: Tuyệt đối không gửi hay chia sẻ nội dung tin nhắn rác hoặc thông tin nhạy cảm của người dùng ra bên ngoài.
