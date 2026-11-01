# App Admin Android: OCOP Admin Gugugaga

App quản trị cho người quản lý sàn OCOP (đề 05), viết bằng **Java + XML**, minSdk 24, gọi backend chung bằng Retrofit 2 + Gson theo Phụ lục 2. Tổ chức mã nguồn và quy ước theo [Architecture](../docs/development/Architecture.md) và [Labs Android](../docs/development/Labs_Android.md).

**Mã nhóm:** `gugugaga`. Thông tin định danh của app:
- tên app: `OCOP Admin Gugugaga`;
- package: `vn.edu.vhu.ltdd.gugugaga.admin`;
- TAG log: `GUGUGAGA_ADMIN`. Lọc Logcat bằng `tag:GUGUGAGA_ADMIN`.

## Tiến độ: 13 màn hình gọi API thật

| Màn hình (lớp) | API | Ghi chú |
| --- | --- | --- |
| Đăng nhập (`LoginActivity`) | `POST /auth/dang-nhap` | Kiểm tra form, lưu token bằng `SharedPreferences`; chỉ nhận `QUAN_TRI`, `NHAN_VIEN` (từ chối `KHACH`, `NHA_CUNG_CAP` và không lưu token); tự vào màn hình chính nếu đã có token |
| Sản phẩm (`SanPhamFragment`) | `GET /quan-tri/san-pham?trangThai=`, `PATCH /san-pham/:id/duyet` | RecyclerView, Spinner lọc; `QUAN_TRI` duyệt (chọn 3/4/5 sao) hoặc từ chối (bắt buộc lý do); `NHAN_VIEN` chỉ xem |
| Lô (`lo/LoFragment`) | `GET /lo-san-xuat` | RecyclerView 100 lô mới nhất; nút nổi "Tạo lô" |
| Chi tiết lô và QR (`lo/ChiTietLoFragment`) | `GET /lo-san-xuat/:id`, `POST /lo-san-xuat/:id/buoc` | Ảnh QR vẽ từ `duongDanTruyXuat` bằng zxing core; các bước; thêm bước (`ThemBuocDialog`, thời điểm `+07:00`); chia sẻ đường dẫn (`ACTION_SEND`) |
| Tạo lô (`lo/TaoLoFragment`) | `GET /quan-tri/san-pham`, `POST /lo-san-xuat` | Spinner sản phẩm, `DatePickerDialog`, kiểm tra 4 lớp báo lỗi đúng ô (cả lỗi 400 `chiTiet[].truong` của backend); giữ dữ liệu khi xoay bằng `onSaveInstanceState` |
| Đơn hàng (`donhang/DonHangFragment`) | `GET /quan-tri/don-hang?trangThai=` | RecyclerView, Spinner lọc 7 trạng thái |
| Chi tiết đơn (`donhang/ChiTietDonHangFragment`) | `GET /quan-tri/don-hang/:id`, `PATCH /don-hang/:id/trang-thai` | Người nhận (bấm số mở `ACTION_DIAL`), tổng tiền, dòng hàng kèm mã truy xuất lô đã giao, lịch sử; chỉ hiện bước hợp lệ; xác nhận trước mỗi bước, hủy bắt buộc lý do |
| Phản ánh (`phananh/PhanAnhFragment`) | `GET /quan-tri/bao-cao-vi-pham?trangThai=` | RecyclerView, Spinner lọc |
| Chi tiết phản ánh (`phananh/ChiTietPhanAnhFragment`) | `GET`/`PATCH /quan-tri/bao-cao-vi-pham/:id` | Chỉ đi tới; kết quả bắt buộc khi Đã xử lý/Bác bỏ |
| Nhà cung cấp (`nhacungcap/NhaCungCapFragment`) | `GET /quan-tri/nha-cung-cap?trangThai=` | Mở từ tab Tài khoản; nhãn "tự gửi từ app Client" (`tuGui`) |
| Hồ sơ nhà cung cấp (`nhacungcap/ChiTietNhaCungCapFragment`) | `GET /quan-tri/nha-cung-cap/:id`, `PATCH /nha-cung-cap/:id/duyet` | Ảnh cơ sở, chứng nhận (ảnh, hạn, còn hiệu lực), lý do từ chối; `QUAN_TRI` duyệt/từ chối/thu hồi, `NHAN_VIEN` chỉ xem |
| Báo cáo doanh số (`baocao/BaoCaoFragment`) | `GET /bao-cao/doanh-so?tu=&den=` | Chỉ `QUAN_TRI` thấy lối vào; biểu đồ cột **tự vẽ** bằng Canvas (`BieuDoCotView`) theo vùng và theo hạng sao; top 5 nhà cung cấp; lọc ngày bằng `DatePickerDialog` |
| Tài khoản (`TaiKhoanFragment`) | — | Thông tin phiên, lối vào Nhà cung cấp và Báo cáo, đăng xuất có xác nhận |

Điều hướng: `BottomNavigationView` 5 tab (Sản phẩm, Lô, Đơn hàng, Phản ánh, Tài khoản). Chi tiết mở bằng `newInstance` + arguments + `addToBackStack`; chi tiết báo kết quả về danh sách bằng Fragment Result API để tải lại. Ảnh (cơ sở, chứng nhận, hiện trường, phản ánh) tải bằng `data/AnhRepository` qua một OkHttp riêng **không gắn token**.

### Đối chiếu yêu cầu C.1

| # | Yêu cầu | Cách đáp ứng |
| --- | --- | --- |
| 1 | Đăng nhập, lưu token, tự đăng xuất khi hết hạn | `LoginActivity` + `TokenStore`; mọi API trả 401 thì `GoiApi` xóa token, màn hình gọi `MainActivity.dangXuat(true)` |
| 2 | ≥ 2 vai trò thấy chức năng khác nhau | `QUAN_TRI`: nút duyệt/từ chối sản phẩm và hồ sơ, lối vào Báo cáo. `NHAN_VIEN`: chỉ xem các mục đó. Backend vẫn chặn bằng 403 |
| 3 | ≥ 2 RecyclerView + Adapter + ViewHolder | 5 danh sách: sản phẩm, lô, đơn hàng, phản ánh, nhà cung cấp |
| 4 | Nhiều màn hình bằng Fragment | 1 `MainActivity` + 12 Fragment, back stack cho màn hình chi tiết |
| 5 | Form kiểm tra hợp lệ, báo lỗi đúng chỗ | Tạo lô, thêm bước, lý do hủy/từ chối, kết quả xử lý phản ánh, khoảng ngày báo cáo |
| 6 | Hộp thoại xác nhận, Toast/Snackbar | `XacNhanDialog` trước mỗi chuyển trạng thái đơn, xử lý phản ánh, duyệt/từ chối hồ sơ, đăng xuất; Snackbar báo kết quả (Toast khi chưa chọn sản phẩm) |
| 7 | ≥ 1 màn hình báo cáo có biểu đồ | `BaoCaoFragment` + `BieuDoCotView` tự vẽ (không dùng MPAndroidChart) |
| 8 | Đủ 3 trạng thái gọi API | `ui/chung/KhungTrangThai` + `layout/khung_trang_thai.xml`: ProgressBar / nội dung hoặc dòng trống / lỗi + Thử lại, ở mọi màn hình gọi API |
| 9 | Không mất dữ liệu form khi xoay | EditText có id tự khôi phục; `TaoLoFragment`, `ThemBuocDialog`, `BaoCaoFragment` lưu lựa chọn và ngày bằng `onSaveInstanceState`; dữ liệu tải về giữ trong ViewModel |
| 10 | Tên app và TAG chứa mã nhóm | `OCOP Admin Gugugaga`, package `vn.edu.vhu.ltdd.gugugaga.admin`, `TAG = "GUGUGAGA_ADMIN"` |

Chưa làm (không bắt buộc): chọn vùng nguyên liệu riêng cho lô (backend mặc định vùng nhà cung cấp), tải ảnh lên từ máy (form nhận URL ảnh), phân trang quá 100 dòng mỗi danh sách, nhập hồ sơ nhà cung cấp/sản phẩm mới từ app Admin.

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

- **`kientruc/KienTrucTest`:** ArchUnit kiểm tra kiến trúc gồm phân tầng `ui → data → model`, màn hình chỉ gọi API qua repository, Retrofit/Gson chỉ ở data, `SharedPreferences` chỉ ở `TokenStore`, không gọi mạng đồng bộ, Fragment chỉ có constructor rỗng, ViewModel không giữ View. Danh sách đầy đủ trong [Architecture](../docs/development/Architecture.md#kiểm-tra-kiến-trúc-hai-app-bằng-máy). `KienTrucTuKiemTest` chứng minh các quy tắc bắt được vi phạm.
- **`DinhDangTest`, `QuyTacTrangThaiTest`, `BieuDoTest`, `KiemTraFormTest`:** chạy không cần máy ảo. Kiểm tra định dạng tiền/ngày giờ (UTC → giờ Việt Nam, thời điểm gửi lên có `+07:00`), cách đọc lỗi và lỗi theo ô của backend, body gửi lên không có trường null, nút chuyển trạng thái hợp lệ của đơn/phản ánh/hồ sơ, vai trò được dùng app, tỉ lệ cột biểu đồ (không chia cho 0, doanh số vượt `int`), bốn lớp kiểm tra số lượng và URL ảnh.
- **`ApiContractTest`:** gọi backend **thật** để kiểm tra model của app đọc đúng JSON của mọi API app dùng (đơn hàng, nhà cung cấp, lô, phản ánh, báo cáo), và backend trả đúng 400/403/409 ở các trường hợp app đã chặn (hủy không lý do, nhảy cóc trạng thái, nhân viên duyệt, nhân viên xem báo cáo, hạn trước ngày sản xuất). Một số test có ghi dữ liệu (duyệt sản phẩm 45, tạo một lô, chuyển một đơn sang Đang giao), nên chạy trên CSDL vừa reset. Test tự bỏ qua nếu chưa đặt biến môi trường. Muốn chạy, khởi động backend sau khi `npm run db:reset -- --yes`, rồi chạy:

  ```bash
  OCOP_API_TEST_URL=http://localhost:3000/ ./gradlew testDebugUnitTest
  ```

**Lần kiểm tra gần nhất** (`./gradlew testDebugUnitTest lintDebug assembleDebug assembleRelease`, backend cục bộ vừa `db:reset`):
- `BUILD SUCCESSFUL`; đã tạo `app-debug.apk` và `app-release-unsigned.apk`;
- 63 unit test đạt: 13 quy tắc ArchUnit, 3 test tự kiểm, 27 test logic thuần (định dạng, quy tắc trạng thái, biểu đồ, kiểm tra form), 20 contract test với backend thật (khi không đặt `OCOP_API_TEST_URL` thì 20 test này tự bỏ qua);
- lint 0 lỗi (còn cảnh báo về phiên bản thư viện, `notifyDataSetChanged`, plurals).

**Chưa chạy thử giao diện trên máy ảo hoặc điện thoại thật**, nên nhóm cần chạy và chụp màn hình khi demo.
