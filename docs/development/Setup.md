# Cài đặt và chạy dự án

Hướng dẫn cho thành viên mới: cài công cụ, chạy backend, hai app và bộ kiểm thử trên máy cá nhân. Đọc [Architecture](Architecture.md) để hiểu code được tổ chức thế nào, và [Contributing](Contributing.md) để biết quy trình làm việc nhóm.

Các lệnh dưới đây viết cho **Windows PowerShell**. Lệnh cho macOS/Linux chỉ khác ở chỗ ghi chú.

## 1. Tổng quan: chạy với gì

| Phần | Thư mục | Cần cài | Chạy với |
| --- | --- | --- | --- |
| Backend REST API | `backend/` | Node.js 20+, PostgreSQL 16 (để chạy test) | CSDL cục bộ hoặc Supabase |
| App Admin | `admin-android/` | Android Studio (kèm JDK 17+ và Android SDK 36) | Máy ảo hoặc điện thoại Android |
| App Client | `client-flutter/` | Flutter 3.35+ (Dart 3), Android SDK | Máy ảo hoặc điện thoại Android |

Có hai cách làm việc. Chọn cách phù hợp với phần bạn phụ trách:

- **Chỉ làm app (nhanh nhất):** không cần chạy backend. Trỏ app tới backend đã deploy `https://ocop-backend.onrender.com` (xem [mục 5.3](#53-trỏ-app-tới-backend-đã-deploy)).
- **Làm backend hoặc cả hệ thống:** chạy backend và PostgreSQL trên máy, app trỏ tới `http://10.0.2.2:3000`, tức máy tính khi nhìn từ máy ảo.

## 2. Môi trường đang chạy (dùng chung cả nhóm)

| Thành phần | Địa chỉ | Ghi chú |
| --- | --- | --- |
| API | https://ocop-backend.onrender.com | Render gói Free, Frankfurt. Tự deploy lại mỗi khi `main` có commit mới |
| Kiểm tra sức khỏe | https://ocop-backend.onrender.com/health | Trả `{"trangThai":"ok","csdl":"ok"}` |
| CSDL | Supabase project `Gugugaga-Android` (eu-west-1) | Chủ project cấp quyền xem trên dashboard Supabase |

Tài khoản thử nghiệm (mật khẩu chung `Demo@12345`):

| Vai trò | Email | Dùng ở |
| --- | --- | --- |
| `QUAN_TRI` | `quantri@ocop.example` | App Admin: thấy thêm nút duyệt |
| `NHAN_VIEN` | `nhanvien@ocop.example` | App Admin: nhập liệu, lô, đơn |
| `KHACH` | `khach1@ocop.example` … `khach5@ocop.example` | App Client |

Một số lưu ý về môi trường dùng chung:

- **Render ngủ sau 15 phút** không có yêu cầu. Lần gọi đầu tiên mất tới một phút, nên hai app đặt timeout 90 giây.
- **Supabase tạm dừng project sau 7 ngày** không hoạt động. Nếu `/health` trả 503, vào dashboard Supabase bấm khôi phục.
- **Dữ liệu trên Supabase là dữ liệu demo dùng chung.** Không chạy `db:reset` hay xóa dữ liệu trên đó khi chưa báo cả nhóm.
- **Mật khẩu CSDL, `JWT_SECRET` và khóa Supabase chỉ nằm trong mục Environment trên Render.** Không gửi qua chat, không commit. Ai cần thì hỏi chủ tài khoản.

## 3. Lấy mã nguồn

```powershell
git clone https://github.com/TruongSoCute/Gugugaga-AndroidProject.git
```

```powershell
cd Gugugaga-AndroidProject
```

Cấu hình Git bằng **tài khoản GitHub của chính bạn**. Lịch sử commit là minh chứng đóng góp cá nhân khi chấm điểm (xem [Delivery](../course/Delivery.md)).

```powershell
git config user.name "Tên GitHub của bạn"
```

```powershell
git config user.email "email-dang-ky-github@example.com"
```

## 4. Backend

### 4.1. Cài PostgreSQL trên máy

Backend cần một CSDL PostgreSQL. Bộ kiểm thử bắt buộc dùng **CSDL riêng**, vì mỗi lần chạy test sẽ xóa và tạo lại CSDL đó. Chọn một trong hai cách:

- **Cài trực tiếp:** tải PostgreSQL 16 tại https://www.postgresql.org/download/windows/, nhớ mật khẩu của user `postgres`. Sau đó tạo hai CSDL `ocop_dev` và `ocop_test` bằng pgAdmin, hoặc:

  ```powershell
  psql -U postgres -c "CREATE DATABASE ocop_dev;" -c "CREATE DATABASE ocop_test;"
  ```
- **Dùng Docker** (nếu đã có Docker Desktop):

  ```powershell
  docker run -d --name ocop-pg -e POSTGRES_PASSWORD=postgres -p 5432:5432 postgres:16
  ```

  ```powershell
  docker exec ocop-pg psql -U postgres -c "CREATE DATABASE ocop_dev;" -c "CREATE DATABASE ocop_test;"
  ```

### 4.2. Cài thư viện và cấu hình

```powershell
cd backend
```

```powershell
npm install
```

```powershell
Copy-Item .env.example .env
```

Sửa file `backend/.env`. File này đã nằm trong `.gitignore` nên không bị commit.

```properties
DATABASE_URL=postgresql://postgres:<mật-khẩu>@localhost:5432/ocop_dev
DATABASE_SSL=false
JWT_SECRET=<chuỗi ngẫu nhiên, tạo bằng lệnh bên dưới>
TEST_DATABASE_URL=postgresql://postgres:<mật-khẩu>@localhost:5432/ocop_test
PUBLIC_BASE_URL=
```

Tạo `JWT_SECRET`:

```powershell
node -e "console.log(require('crypto').randomBytes(48).toString('base64url'))"
```

### 4.3. Tạo bảng, dữ liệu mẫu và chạy server

Lệnh dưới đây **xóa toàn bộ dữ liệu** trong CSDL của `DATABASE_URL`, rồi chạy `db/schema.sql` và `db/seed.sql`:

```powershell
npm run db:reset -- --yes
```

Chạy server ở chế độ tự khởi động lại khi sửa code:

```powershell
npm run dev
```

Mở http://localhost:3000/health. Kết quả mong đợi là `{"trangThai":"ok","csdl":"ok",...}`.

Mã truy xuất của 100 lô mẫu được sinh ngẫu nhiên mỗi lần seed. Để lấy vài mã thử quét QR:

```powershell
psql "postgresql://postgres:<mật-khẩu>@localhost:5432/ocop_dev" -c "SELECT ma_truy_xuat FROM lo_san_xuat LIMIT 5;"
```

### 4.4. Kiểm thử backend

Chạy riêng phần kiểm tra kiến trúc (không cần CSDL):

```powershell
npm run check:arch
```

Chạy toàn bộ test. `TEST_DATABASE_URL` được đọc từ `.env`:

```powershell
npm test
```

Kết quả mong đợi: `# pass 59`, `# fail 0` (số test tăng dần khi nhóm thêm chức năng).

### 4.5. Gọi thử API

Ví dụ với PowerShell: đăng nhập, rồi gọi API cần token.

```powershell
$dn = Invoke-RestMethod -Method Post -Uri http://localhost:3000/auth/dang-nhap -ContentType 'application/json' -Body '{"email":"nhanvien@ocop.example","matKhau":"Demo@12345"}'
```

```powershell
Invoke-RestMethod -Uri "http://localhost:3000/quan-tri/don-hang?kichThuoc=3" -Headers @{ Authorization = "Bearer $($dn.token)" }
```

Có thể dùng Postman thay cho PowerShell. Danh sách API, quyền và mã lỗi: [API](API.md).

## 5. App Admin (Android, Java/XML)

### 5.1. Mở và chạy

1. Cài **Android Studio** bản mới (đã kèm JDK và Android SDK). Trong SDK Manager, cài **Android SDK Platform 36**.
2. *File → Open*, chọn thư mục `admin-android/` (không mở thư mục gốc của repo), rồi chờ Gradle sync xong. Project dùng AGP 9.5, Gradle 9.8 và Java 17.
3. Tạo máy ảo trong *Device Manager* (API 24 trở lên), rồi bấm **Run**.
4. Đăng nhập bằng `quantri@ocop.example` hoặc `nhanvien@ocop.example`.

Bản debug gọi `ocopApiBaseUrlDebug` trong `admin-android/gradle.properties`, mặc định là `http://10.0.2.2:3000/`, tức backend chạy trên máy tính. Bản debug cho phép `http`; bản release chỉ cho `https`.

### 5.2. Kiểm thử

```powershell
cd admin-android
```

```powershell
.\gradlew.bat testDebugUnitTest lintDebug
```

Trên macOS/Linux dùng `./gradlew`. Lệnh này chạy kiểm tra kiến trúc ArchUnit (`KienTrucTest`), test định dạng và lint. `ApiContractTest` gọi backend thật và tự bỏ qua nếu chưa đặt biến môi trường. Muốn chạy:

```powershell
$env:OCOP_API_TEST_URL = "http://localhost:3000/"; .\gradlew.bat testDebugUnitTest
```

### 5.3. Trỏ app tới backend đã deploy

Không cần chạy backend trên máy. Để **không sửa file đã commit**, đặt địa chỉ trong file Gradle cấp người dùng `%USERPROFILE%\.gradle\gradle.properties` (macOS/Linux: `~/.gradle/gradle.properties`). Giá trị ở đây được ưu tiên hơn file trong repo:

```properties
ocopApiBaseUrlDebug=https://ocop-backend.onrender.com/
```

Sync Gradle lại rồi chạy. Muốn quay về backend trên máy thì xóa dòng này.

**Điện thoại thật cùng Wi-Fi với máy tính:** thay bằng `http://<IP-máy-tính>:3000/`. Xem IP bằng lệnh `ipconfig`.

### 5.4. Build APK release

Cần khóa ký `.jks` của nhóm và file `admin-android/keystore.properties`. **Cả hai không được commit.** Cách tạo khóa và nội dung file: [admin-android/README](../../admin-android/README.md#build-apk-release-để-nộp).

```powershell
.\gradlew.bat assembleRelease
```

APK nằm ở `admin-android/app/build/outputs/apk/release/`. Bản release luôn gọi `ocopApiBaseUrlRelease`, tức `https://ocop-backend.onrender.com/`.

## 6. App Client (Flutter)

### 6.1. Cài và chạy

1. Cài Flutter theo https://docs.flutter.dev/get-started/install/windows (bản 3.35 trở lên). Chạy `flutter doctor` và sửa hết các dòng báo lỗi liên quan tới Android.
2. Mở thư mục `client-flutter/` bằng VS Code (cài extension Flutter) hoặc Android Studio (cài plugin Flutter).
3. Cài thư viện:

   ```powershell
   cd client-flutter
   ```

   ```powershell
   flutter pub get
   ```
4. Chạy, chọn một trong ba:
   - Với backend trên máy (máy ảo Android):

     ```powershell
     flutter run
     ```
   - Với backend đã deploy:

     ```powershell
     flutter run --dart-define=API_BASE_URL=https://ocop-backend.onrender.com
     ```
   - Điện thoại thật cùng Wi-Fi, backend trên máy:

     ```powershell
     flutter run --dart-define=API_BASE_URL=http://<IP-máy-tính>:3000
     ```

Địa chỉ API được truyền lúc build qua `--dart-define`, đọc trong `lib/config.dart`, nên không cần sửa code khi đổi môi trường.

### 6.2. Kiểm thử

```powershell
flutter analyze
```

```powershell
flutter test
```

`test/kien_truc_test.dart` kiểm tra kiến trúc. `test/api_backend_test.dart` gọi backend thật và tự bỏ qua nếu chưa đặt biến:

```powershell
$env:OCOP_API_TEST_URL = "http://localhost:3000"; $env:OCOP_MA_LO_TEST = "<mã lô>"; flutter test test/api_backend_test.dart
```

### 6.3. Build APK release

```powershell
flutter build apk --release --dart-define=API_BASE_URL=https://ocop-backend.onrender.com
```

APK nằm ở `client-flutter/build/app/outputs/flutter-apk/app-release.apk`. Khi chưa có `android/key.properties`, bản release tạm ký bằng khóa debug, vẫn cài được để demo. Xem [client-flutter/README](../../client-flutter/README.md#build-apk-release-để-nộp).

## 7. Triển khai (chủ tài khoản Render/Supabase)

Thường không cần làm lại, vì **push lên `main` là Render tự build và deploy**. Phần này để tham khảo khi cần dựng lại từ đầu.

1. **Supabase:** tạo project, rồi chạy `backend/db/schema.sql` và sau đó `backend/db/seed.sql` trong *SQL Editor*. Lấy chuỗi kết nối tại *Connect → Session pooler* (cổng 5432). Không dùng Direct connection, vì nó chỉ có IPv6 mà Render không hỗ trợ.
2. **Render:** *New → Blueprint*, chọn repo và nhánh `main`. Render đọc [`render.yaml`](../../render.yaml): Node 20, thư mục `backend`, health check `/health`, region Frankfurt, tự sinh `JWT_SECRET`. Bạn nhập thêm:
   - `DATABASE_URL`: chuỗi Session pooler đã điền mật khẩu;
   - `PUBLIC_BASE_URL`: `https://<tên-service>.onrender.com`, dùng làm nội dung QR.
3. Mở `/health` từ một máy khác và kiểm tra nhận được mã 200.

**Đổi cấu trúc CSDL trên Supabase:** `schema.sql` xóa và tạo lại toàn bộ bảng. Trên CSDL dùng chung, hãy viết câu `ALTER TABLE …` tương ứng và chạy trong SQL Editor, đồng thời cập nhật `schema.sql`/`seed.sql` trong cùng commit. Chỉ chạy lại toàn bộ `schema.sql` + `seed.sql` khi cả nhóm đồng ý xóa dữ liệu demo.

## 8. Gặp lỗi thường gặp

| Hiện tượng | Nguyên nhân thường gặp | Cách xử lý |
| --- | --- | --- |
| `npm test` báo `Cần đặt TEST_DATABASE_URL` | Thiếu biến trong `.env` | Thêm `TEST_DATABASE_URL` trỏ tới CSDL `ocop_test` |
| `npm test` báo `TEST_DATABASE_URL phải khác DATABASE_URL` | Hai biến trỏ cùng một CSDL | Dùng CSDL riêng cho test, vì test sẽ xóa dữ liệu |
| Server dừng ngay với `Thiếu biến môi trường JWT_SECRET` | `.env` hoặc Render thiếu biến | Thêm `JWT_SECRET` dài ít nhất 32 ký tự |
| `/health` trả 503 | Không kết nối được CSDL | Kiểm tra `DATABASE_URL`, PostgreSQL đang chạy, hoặc Supabase bị tạm dừng |
| Render log `Tenant or user not found` | Sai host pooler hoặc sai user | Copy lại chuỗi *Session pooler* từ Supabase |
| App báo lỗi mạng khi chạy máy ảo | Backend trên máy chưa chạy, hoặc gọi `localhost` thay vì `10.0.2.2` | Chạy `npm run dev`; máy ảo phải dùng `10.0.2.2` |
| Điện thoại thật không gọi được backend trên máy | Khác mạng Wi-Fi hoặc tường lửa chặn cổng 3000 | Cùng Wi-Fi; mở cổng 3000 trong Windows Defender Firewall |
| Lần gọi đầu tới Render rất lâu | Render gói Free đang ngủ | Bình thường; chờ tới một phút |
| `./gradlew testDebugUnitTest` đỏ ở `KienTrucTest` | Code vi phạm quy tắc tầng | Sửa code cho đúng tầng, **không** sửa quy tắc. Xem [Architecture](Architecture.md#kiểm-tra-kiến-trúc-hai-app-bằng-máy) |
