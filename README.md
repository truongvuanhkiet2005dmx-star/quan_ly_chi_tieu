# Quan ly chi tieu

## Gioi thieu do an

Quan ly chi tieu la ung dung ho tro ghi chep, theo doi va thong ke cac giao dich tai chinh ca nhan. Giao dien va du lieu hien tai cua he thong chinh phan o phan frontend, duoc xay dung bang Flutter.

## Cau truc du an

```text
quan_ly_chi_tieu/
|-- frontend/       Du an Flutter hien tai
`-- backend/        Phan ASP.NET Core C#, hien dang phat trien
```

### Frontend

Thu muc `frontend/` chua toan bo du an Flutter hien co. Phan frontend da co cac man hinh va chuc nang lien quan den dang nhap, vi tien, giao dich, lich, bao cao, muc tiet kiem, quet hoa don va xu ly thong bao/SMS. Du lieu dia phuong duoc xu ly thong qua cac thu vien va file co so du lieu trong du an.

### Backend

Thu muc `backend/` hien chua `/.gitkeep` vi ma nguon C# ASP.NET Core chua duoc cung cap. Backend dang trong qua trinh phat trien va chua co huong dan chay API cu the trong phan nay.

## Tai ma nguon bang ZIP

1. Mo trang GitHub: https://github.com/truongvuanhkiet2005dmx-star/quan_ly_chi_tieu
2. Chon nut `Code`.
3. Chon `Download ZIP`.
4. Giai nen tep ZIP va mo thu muc goc cua du an bang VS Code hoac IDE phu hop.

## Huong dan chay frontend

Yeu cau hien co: da cai dat Flutter SDK va cac cong cu phat trien cua nen tang muon chay ung dung. Khong thay the hoac cap nhat cac rang buoc SDK trong du an neu chua kiem tra tinh tuong thich.

```powershell
cd frontend
flutter pub get
flutter run
```

Lenh tren duoc thuc hien trong thu muc `frontend/`. Cach chay tren tung thiet bi Android, iOS, web hay desktop phu thuoc vao SDK va thiet bi da duoc cau hinh trong moi truong local; repo hien khong dat thong tin dau vao API hay dich vu may chu rieng.

## Backend

Backend C# ASP.NET Core chua duoc tao ma nguon. Khi duoc bo sung, phai kiem tra lai day du project file, SDK, database, cau hinh va cong API trong repo truoc khi viet huong dan chay cu the.

## Tinh trang hoan thien

- Frontend Flutter: da co cau truc du an va nhieu man hinh/chuc nang co ban.
- Backend ASP.NET Core C#: dang phat trien; chua co ma nguon trong repository.
- Tich hop frontend-backend va tai lieu cau hinh may chu: chua hoan tat cho den khi backend duoc bo sung.

## Tieu chuan git

File `.gitignore` o thu muc goc loai bo cac thu muc build, cache, file sinh tu dong va du lieu tam cua ca frontend Flutter/Dart lan backend .NET neu sau nay duoc bo sung.

Khong luu mat khau, API key, thong tin ca nhan hoac du lieu nhay cam vao README hoac cac tep duoc dua len repository.
