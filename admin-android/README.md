# App Admin Android: OCOP Admin Gugugaga

App quản trị cho người quản lý sàn OCOP (đề 05), viết bằng **Java + XML**, minSdk 24, gọi backend chung bằng Retrofit 2 + Gson theo Phụ lục 2. Tổ chức mã nguồn và quy ước theo [Architecture](../docs/development/Architecture.md) và [Labs Android](../docs/development/Labs_Android.md).

**Mã nhóm:** `gugugaga`. Thông tin định danh của app:
- tên app: `OCOP Admin Gugugaga`;
- package: `vn.edu.vhu.ltdd.gugugaga.admin`;
- TAG log: `GUGUGAGA_ADMIN`. Lọc Logcat bằng `tag:GUGUGAGA_ADMIN`.

## Tiến độ (mốc tuần 11: 2 màn hình gọi API thật)

| Màn hình | API | Ghi chú |
| --- | --- | --- |
| Đăng nhập (`LoginActivity`) | `POST /auth/dang-nhap` | Kiểm tra form, lưu token bằng `SharedPreferences`; từ chối tài khoản `KHACH`; tự vào màn hình chính nếu đã có token |
| Sản phẩm (`SanPhamFragment`) | `GET /quan-tri/san-pham?trangThai=`, `PATCH /san-pham/:id/duyet` | RecyclerView, Spinner lọc trạng thái; `QUAN_TRI` duyệt (chọn 3/4/5 sao) hoặc từ chối (bắt buộc lý do); `NHAN_VIEN` chỉ xem |
| Tài khoản (`TaiKhoanFragment`) | — | Thông tin phiên, đăng xuất có hộp thoại xác nhận |

Các yêu cầu C.1 đã có:
- đăng nhập, lưu token, tự đăng xuất khi API trả 401;
- 2 vai trò thấy chức năng khác nhau (backend vẫn chặn bằng 403);
- danh sách dùng RecyclerView;
- một Activity + Fragment và BottomNavigationView;
- kiểm tra form, báo lỗi đúng ô;
- hộp thoại xác nhận;
- đủ 3 trạng thái gọi API: đang tải / thành công / lỗi + Thử lại;
- xoay màn hình không mất dữ liệu (ViewModel, DialogFragment);
- tên app và TAG chứa mã nhóm.

Còn thiếu so với C.1: danh sách RecyclerView thứ hai, màn hình báo cáo có biểu đồ, và đủ 6 màn hình. Các chức năng nhà cung cấp, lô/QR, đơn hàng và phản ánh chưa làm.

## Chạy

1. Mở thư mục `admin-android/` bằng Android Studio và chờ Gradle sync. Project dùng AGP 9.5, Gradle 9.8 và compileSdk 36.
2. Chạy backend trên máy (xem [backend/README](../backend/README.md)). Bản debug gọi `http://10.0.2.2:3000/`, tức là máy tính khi chạy trên máy ảo.
   - Dùng điện thoại thật cùng Wi-Fi: sửa `ocopApiBaseUrlDebug` trong `gradle.properties` thành `http://<IP-máy-tính>:3000/`.
   - Bản debug cho phép `http`; bản release chỉ cho `https`.
3. Đăng nhập bằng tài khoản thử nghiệm trong seed:
   - `quantri@ocop.example` (Quản trị);
   - `nhanvien@ocop.example` (Nhân viên).

   Mật khẩu chung `Demo@12345`.

## Build APK release để nộp

1. Sau khi deploy backend, sửa `ocopApiBaseUrlRelease` trong `gradle.properties` thành địa chỉ Render (có `/` ở cuối).
2. Tạo khóa ký **một lần** và giữ riêng trong nhóm. **Không commit** khóa này:

   ```bash
   keytool -genkeypair -v -keystore gugugaga-admin.jks -alias gugugaga -keyalg RSA -keysize 2048 -validity 10000
   ```

3. Tạo file `admin-android/keystore.properties` (đã có trong `.gitignore`):

   ```properties
   storeFile=gugugaga-admin.jks
   storePassword=...
   keyAlias=gugugaga
   keyPassword=...
   ```

4. Build: `./gradlew assembleRelease`, hoặc trong Android Studio chọn *Build → Generate Signed App Bundle / APK*. File APK nằm ở `app/build/outputs/apk/release/`. Nếu chưa có `keystore.properties`, Gradle tạo `app-release-unsigned.apk`, file này **không cài được** lên máy.

## Kiểm thử

```bash
./gradlew testDebugUnitTest lintDebug
```

- **`DinhDangTest`:** chạy không cần máy ảo, kiểm tra định dạng tiền, cách đọc lỗi của backend và body duyệt.
- **`ApiContractTest`:** gọi backend **thật** để kiểm tra model của app đọc đúng JSON. Test tự bỏ qua nếu chưa đặt biến môi trường. Muốn chạy, khởi động backend sau khi `npm run db:reset -- --yes`, rồi chạy:

  ```bash
  OCOP_API_TEST_URL=http://localhost:3000/ ./gradlew testDebugUnitTest
  ```

**Lần kiểm tra gần nhất:**
- đã chạy được `assembleDebug` và `assembleRelease`;
- 9/9 unit test đạt, tính cả contract test với backend cục bộ;
- lint 0 lỗi.

**Chưa chạy thử giao diện trên máy ảo hoặc điện thoại thật**, nên nhóm cần chạy và chụp màn hình khi demo.
