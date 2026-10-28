# Backend quản lý chi tiêu

## Cấu hình Firebase

Backend xác thực Firebase ID token bằng Firebase Project ID. Không cần service account hoặc private key cho API này.

Thiết lập một trong hai cách:

- Biến môi trường (khuyến nghị cho môi trường chạy): `FIREBASE_PROJECT_ID=<Firebase Project ID>`
- Cấu hình trong `appsettings.json` hoặc `appsettings.Development.json`: `Firebase:ProjectId`

Trong PowerShell:

```powershell
$env:FIREBASE_PROJECT_ID = "<Firebase Project ID>"
dotnet run
```

Nếu thiếu Project ID, server sẽ từ chối khởi động và báo lỗi cấu hình rõ ràng.

## Chạy backend

```powershell
cd <thư-mục-backend>
dotnet restore
dotnet build
dotnet run
```

Trong môi trường Development, Swagger: `http://localhost:5104/swagger`.

Trong Swagger, chọn nút **Authorize**, nhập Firebase ID token (Swagger tự thêm tiền tố Bearer), sau đó thử API. Khi gọi bằng HTTP client, gửi header:

```http
Authorization: Bearer <Firebase ID token>
```

`GET /health` không yêu cầu đăng nhập. Hai API giao dịch yêu cầu Firebase ID token hợp lệ:

- `GET /api/transactions`
- `POST /api/transactions`

`OccurredAt` được chuẩn hóa về UTC trước khi lưu và kiểm tra giao dịch trùng. SQLite lưu dữ liệu tại `smartmoney.db`. Backend chạy EF Core migrations khi khởi động; không xóa database để cập nhật schema.

Các file database, WAL, build output, IDE state và cấu hình secret local đã được bỏ qua bởi Git. Production bật HSTS và HTTPS redirection; Development vẫn cho phép chạy HTTP local.
