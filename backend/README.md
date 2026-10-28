# Backend quản lý chi tiêu

Backend ASP.NET Core .NET 8 sử dụng Firebase Authentication để bảo vệ API giao dịch và SQLite để lưu dữ liệu.

## Cấu hình Firebase

Backend đọc Firebase Project ID theo thứ tự:

1. Biến môi trường `FIREBASE_PROJECT_ID`
2. Cấu hình `Firebase:ProjectId` trong `appsettings.json` hoặc `appsettings.Development.json`

Ví dụ cấu hình trong `appsettings.json`:

```json
{
  "Firebase": {
    "ProjectId": "smartmoney-quanlychitieu"
  }
}
```

Hoặc thiết lập cho phiên PowerShell hiện tại:

```powershell
$env:FIREBASE_PROJECT_ID = "smartmoney-quanlychitieu"
```

Backend kiểm tra issuer `https://securetoken.google.com/<Project ID>`, audience bằng Project ID và thời hạn của Firebase ID token. Không cần Firebase service account, private key hoặc secret.

Nếu thiếu Project ID, ứng dụng sẽ dừng khởi động với thông báo cấu hình rõ ràng.

## Chạy backend

Mở terminal tại thư mục backend (thư mục chứa file `.csproj`) và chạy:

```powershell
dotnet restore
dotnet build
dotnet run --launch-profile http
```

Nếu đang ở thư mục gốc repository có thư mục `backend`:

```powershell
cd backend
dotnet restore
dotnet build
dotnet run --launch-profile http
```

Development profile lắng nghe trên `http://0.0.0.0:5104`. Truy cập Swagger tại:

- Máy chạy backend: `http://localhost:5104/swagger`
- Thiết bị trong cùng mạng LAN: `http://<IPv4-LAN>:5104/swagger`

Android Emulator truy cập backend máy chủ qua `http://10.0.2.2:5104`.

Kiểm tra IPv4 LAN bằng lệnh:

```powershell
ipconfig
```

## Dùng Firebase ID token

Lấy Firebase ID token sau khi người dùng đăng nhập thành công bằng Firebase Authentication. Không gửi Firebase Web API key hoặc service account trong header/API request.

Gửi token cho mọi API giao dịch:

```http
Authorization: Bearer <Firebase ID token>
```

Trong Swagger:

1. Mở Swagger UI.
2. Chọn nút **Authorize**.
3. Nhập Firebase ID token.
4. Chọn **Authorize** rồi gọi API.

Ví dụ bằng `curl` trong PowerShell:

```powershell
$token = "<Firebase ID token>"
$headers = @{ Authorization = "Bearer $token" }
Invoke-RestMethod -Uri "http://localhost:5104/api/transactions?page=1&pageSize=20" -Headers $headers
```

Ví dụ thêm giao dịch:

```powershell
$body = @{
  eventId = "unique-event-id-001"
  amount = 50000
  type = "expense"
  source = "bank"
  bankName = "Vietcombank"
  packageName = "com.example.smart_money_v2"
  occurredAt = "2026-10-28T10:30:00+07:00"
  categoryName = "Food"
  note = "Lunch"
} | ConvertTo-Json

Invoke-RestMethod -Method Post -Uri "http://localhost:5104/api/transactions" -Headers $headers -ContentType "application/json" -Body $body
```

UID được lấy từ claim `sub` trong Firebase ID token. DTO không nhận UID và client không thể ghi đè chủ sở hữu giao dịch.

## API chính

- `GET /health`: công khai, kiểm tra kết nối SQLite; trả `200` khi kết nối tốt, `503` khi database không kết nối được.
- `GET /api/transactions?page=1&pageSize=20`: yêu cầu token, chỉ trả giao dịch của UID hiện tại.
- `GET /api/transactions/{id}`: yêu cầu token, chỉ truy cập giao dịch thuộc UID hiện tại.
- `POST /api/transactions`: yêu cầu token; gửi lại cùng `(UID, EventId)` trả `200` kiểu idempotent thay vì tạo bản ghi trùng.
- `DELETE /api/transactions/{id}`: yêu cầu token, chỉ xóa giao dịch thuộc UID hiện tại.

## SQLite và migration

SQLite lưu dữ liệu mặc định tại `smartmoney.db`. Backend chạy EF Core migration khi khởi động để cập nhật schema an toàn, không xóa database hiện có.

Unique index trên `(Uid, EventId)` ngăn lưu trùng ở tầng database.

Các file sau đã được `.gitignore` chặn:

- `*.db`, `*.db-shm`, `*.db-wal`, `*.sqlite`, `*.sqlite3`
- `bin/`, `obj/`, `.vs/`, `*.user`
- `appsettings.Development.json`, `appsettings.*.local.json`, `.env*`
- private key và certificate secrets

## CORS cho Flutter Web

Flutter Web cần origin khớp địa chỉ truy cập trình duyệt trong cấu hình `CorsOrigins` trong `appsettings.json`.

```json
"CorsOrigins": [
  "http://localhost:3000",
  "http://<IPv4-LAN>:3000"
]
```

Có thể dùng biến môi trường:

```powershell
$env:CorsOrigins__0 = "http://localhost:3000"
$env:CorsOrigins__1 = "http://<IPv4-LAN>:3000"
dotnet run --launch-profile http
```

Thay `<IPv4-LAN>` bằng địa chỉ IPv4 LAN thực tế của máy chạy backend hoặc Flutter Web nếu truy cập qua mạng. CORS chủ yếu ảnh hưởng Flutter Web; Android/iOS không dùng CORS của trình duyệt.

Production bật HSTS và HTTPS redirect. Development cho phép HTTP qua launch profile hiện có.
