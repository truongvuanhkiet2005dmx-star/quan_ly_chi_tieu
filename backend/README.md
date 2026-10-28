# Backend quản lý chi tiêu

## Cấu hình Firebase

Backend xác thực Firebase ID token bằng Firebase Project ID. Không cần service account hoặc private key cho API này.

Thiết lập một trong hai cách:

- Biến môi trường: `FIREBASE_PROJECT_ID=<Firebase Project ID>`
- Cấu hình trong `appsettings.json` hoặc `appsettings.Development.json`: `Firebase:ProjectId`

Trong PowerShell:

```powershell
$env:FIREBASE_PROJECT_ID = "smartmoney-quanlychitieu"
dotnet run
```

Nếu thiếu Project ID, server sẽ từ chối khởi động và báo lỗi cấu hình rõ ràng.

## Chạy backend

```powershell
cd backend
 dotnet restore
 dotnet build
 dotnet run --launch-profile http
```

Development profile mặc định lắng nghe trên tất cả mạng: `http://0.0.0.0:5104`.
Từ máy khác hoặc thiết bị thực, dùng địa chỉ IPv4 LAN của máy chạy backend, ví dụ: `http://192.168.1.10:5104`. Android Emulator thường dùng `http://10.0.2.2:5104`.

Swagger Development: `http://localhost:5104/swagger`.

Trong Swagger chọn **Authorize**, nhập Firebase ID token. Swagger tự gửi header:

```http
Authorization: Bearer <Firebase ID token>
```

`GET /health` không yêu cầu đăng nhập. Các API giao dịch yêu cầu Firebase ID token hợp lệ:

- `GET /api/transactions`
- `POST /api/transactions`

Frontend chạy trên Flutter Web phải cấu hình đúng origin xuất hiện trên thanh địa chỉ trình duyệt trong `CorsOrigins`, ví dụ:

```json
"CorsOrigins": [
  "http://localhost:5104",
  "http://localhost:3000",
  "http://192.168.1.10:3000",
  "https://localhost:7146"
]
```

Có thể cấu hình bằng biến môi trường thay vì sửa file:

```powershell
$env:CorsOrigins__0 = "http://192.168.1.10:3000"
$env:CorsOrigins__1 = "http://localhost:3000"
dotnet run --launch-profile http
```

Thay `192.168.1.10` bằng IPv4 LAN thực tế của máy chạy Flutter Web. Flutter Android/iOS không bị giới hạn bởi CORS của trình duyệt.

`OccurredAt` được chuẩn hóa về UTC trước khi lưu và kiểm tra giao dịch trùng. SQLite lưu dữ liệu tại `smartmoney.db`; backend chạy EF Core migrations khi khởi động và không xóa database để cập nhật schema.

Các file database, WAL, build output, IDE state và cấu hình secret local đã được bỏ qua bởi Git. Production bật HSTS và HTTPS redirection; Development cho phép chạy HTTP local.
