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

Swagger mặc định: `http://localhost:5104/swagger`.

Trong Swagger, chọn nút **Authorize**, nhập Firebase ID token (không cần nhập chữ `Bearer` trong ô Bearer của Swagger), sau đó thử API. Khi gọi bằng HTTP client, gửi header:

```http
Authorization: Bearer <Firebase ID token>
```

`GET /health` không yêu cầu đăng nhập. Hai API giao dịch yêu cầu Firebase ID token hợp lệ:

- `GET /api/transactions`
- `POST /api/transactions`

SQLite lưu dữ liệu tại `smartmoney.db`. Các file database và WAL được bỏ qua bởi Git.
