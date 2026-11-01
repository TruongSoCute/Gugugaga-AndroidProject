# App Client Flutter: OCOP Gugugaga

App cho khách mua đặc sản OCOP (đề 05) và cho nhà cung cấp gửi hồ sơ, sản phẩm chờ duyệt, viết bằng **Flutter/Dart**, gọi backend chung bằng gói `http`, lưu token bằng `shared_preferences` (C.2). Tổ chức mã nguồn theo [Architecture](../docs/development/Architecture.md):

```
lib/
  config.dart     địa chỉ API (--dart-define), timeout, TAG
  data/           ApiClient dùng chung, TokenStore, các repository (màn hình không gọi http trực tiếp)
  models/         lớp dữ liệu đọc từ JSON của backend
  screens/        các màn hình
  widgets/        widget dùng lại (ảnh mạng có loadingBuilder/errorBuilder, khối lỗi + Thử lại)
  utils/          định dạng tiền, ngày
```

**Mã nhóm:** `gugugaga`.
- tên app: `OCOP Gugugaga`;
- package: `vn.edu.vhu.ltdd.gugugaga.ocop_client`;
- TAG: `GUGUGAGA_CLIENT`.

## Màn hình

Cùng một app cho hai vai trò. Khách (`KHACH`) xem sản phẩm và truy xuất **không cần đăng nhập**; khi bấm thao tác cần tài khoản (thêm vào giỏ, yêu thích, theo dõi, phản ánh) app mở màn hình đăng nhập, **chờ kết quả** rồi quay lại làm tiếp. Nhà cung cấp (`NHA_CUNG_CAP`, nhóm đã chốt dùng chung app Client) đăng nhập thì thấy bộ tab riêng, không có giỏ/đơn.

**Khách** (tab: Sản phẩm, Truy xuất, Giỏ hàng, Đơn hàng, Tài khoản)

| Màn hình (file) | API | Ghi chú |
| --- | --- | --- |
| Sản phẩm (`san_pham_screen.dart`) | `GET /vung-nguyen-lieu`, `GET /san-pham?vung=&hangSao=` | Lọc vùng, hạng sao; `ListView.builder`; chạm mở chi tiết |
| Chi tiết sản phẩm (`chi_tiet_san_pham_screen.dart`) | `GET /san-pham/:id`, `GET /danh-gia?sanPhamId=`, `PUT /gio-hang/:id`, `GET/PUT/DELETE /yeu-thich` | Nhà cung cấp, chứng nhận (chạm xem ảnh), đánh giá kèm ảnh; chọn số lượng, thêm vào giỏ (cộng dồn), yêu thích, phản ánh |
| Nhà cung cấp (`nha_cung_cap_screen.dart`) | `GET /nha-cung-cap/:id`, `GET/PUT/DELETE /theo-doi` | Ảnh cơ sở, chứng nhận, sản phẩm, số người theo dõi, nút Theo dõi |
| Truy xuất (`tra_cuu_screen.dart`) + Quét QR (`quet_qr_screen.dart`) | — | Quét bằng camera (`mobile_scanner`, trả mã về qua Navigator) hoặc nhập/dán mã; `Form` + `validator` |
| Hành trình lô (`hanh_trinh_screen.dart`) | `GET /truy-xuat/:ma` (công khai) | Đúng một lô; nút **Phản ánh** gửi kèm mã lô |
| Đăng nhập / Đăng ký (`dang_nhap_screen.dart`, `dang_ky_screen.dart`) | `POST /auth/dang-nhap`, `POST /auth/dang-ky` | Chọn loại tài khoản Khách / Nhà cung cấp; lưu token bằng `shared_preferences`; pop trả `NguoiDung` |
| Giỏ hàng (`gio_hang_screen.dart`) | `GET /gio-hang`, `PUT`, `DELETE /gio-hang/:id` | Sửa số lượng; xóa có hộp thoại xác nhận + SnackBar **Hoàn tác** (PUT lại số lượng cũ) |
| Đặt hàng (`dat_hang_screen.dart`) | `GET /don-hang/hinh-thuc-giao`, `POST /don-hang` | Form người nhận; không gửi `cacDong` (đặt cả giỏ); pop trả đơn mới về giỏ → SnackBar và mở chi tiết đơn |
| Đơn hàng của tôi (`don_hang_screen.dart`) | `GET /don-hang?trangThai=` | `ListView.builder`, lọc trạng thái |
| Chi tiết đơn (`chi_tiet_don_screen.dart`) | `GET /don-hang/:id`, `PATCH /don-hang/:id/trang-thai` | Mã lô từng dòng (chạm xem hành trình), lịch sử; Hủy (CHO_XAC_NHAN) và Đã nhận hàng (DA_GIAO) có xác nhận; Đánh giá cho dòng `daDanhGia == false` khi DA_NHAN |
| Đánh giá (`danh_gia_screen.dart`) | `POST /tai-len/anh?mucDich=danh-gia`, `POST /danh-gia` | Chọn sao (bắt buộc), nội dung, tối đa 5 ảnh thật (`image_picker`) |
| Phản ánh (`phan_anh_screen.dart`) + Phản ánh của tôi (`phan_anh_cua_toi_screen.dart`) | `POST /bao-cao-vi-pham`, `GET /bao-cao-vi-pham` | Loại, nội dung, mã lô, ảnh tùy chọn; xem trạng thái và kết quả xử lý |
| Yêu thích (`yeu_thich_screen.dart`), Đang theo dõi (`theo_doi_screen.dart`) | `GET /yeu-thich`, `GET /theo-doi`, `PUT/DELETE` | Bỏ có SnackBar **Hoàn tác** |
| Tài khoản (`tai_khoan_screen.dart`) | — | Thông tin phiên, lối vào các danh sách trên; đăng xuất có xác nhận |

**Nhà cung cấp** (tab: Hồ sơ, Sản phẩm, Truy xuất, Tài khoản)

| Màn hình (file) | API | Ghi chú |
| --- | --- | --- |
| Hồ sơ (`ho_so_ncc_screen.dart`) | `GET /cua-toi/nha-cung-cap` | Trạng thái duyệt, lý do từ chối, chứng nhận; 404 `CHUA_CO_HO_SO` thì mời tạo; DA_DUYET thì khóa sửa |
| Form hồ sơ (`ho_so_ncc_form_screen.dart`) | `POST`/`PUT /cua-toi/nha-cung-cap`, `GET /vung-nguyen-lieu` | Tên, người đại diện, SĐT, địa chỉ, vùng, ảnh cơ sở (tải lên hoặc nhập URL), danh sách chứng nhận (chọn ngày); pop trả hồ sơ |
| Sản phẩm của tôi (`san_pham_cua_toi_screen.dart`) | `GET /cua-toi/san-pham` | `ListView.builder`, chip trạng thái, lý do từ chối, số lô/tồn kho |
| Form sản phẩm (`san_pham_form_screen.dart`) | `POST /cua-toi/san-pham`, `PUT /cua-toi/san-pham/:id` | Tên, giá (số nguyên VND), đơn vị, mô tả, ảnh; sản phẩm DA_DUYET không mở form sửa |

### Đáp ứng yêu cầu C.2 của app Client

| Yêu cầu | Cách làm |
| --- | --- |
| ≥ 6 màn hình | 22 màn hình ở trên |
| Đăng ký/đăng nhập, lưu token bằng `shared_preferences` | `TokenStore` (nơi duy nhất dùng `shared_preferences`) lưu token và thông tin người dùng; mở lại app thì khôi phục phiên rồi kiểm tra `GET /auth/toi` |
| Hết phiên | `ApiClient` nhận 401 cho yêu cầu có token: xóa token, phát `PhienDangNhap.hetPhien` (Stream thuần Dart trong `data/`); `KhungChinh` đóng các màn hình và mở đăng nhập |
| Navigator trả kết quả | Đăng nhập trả `NguoiDung`; Đặt hàng trả `DonHang`; Quét QR trả mã; Đánh giá/Phản ánh trả `true`; form hồ sơ/sản phẩm trả bản ghi; chi tiết đơn trả "đã đổi" để danh sách tải lại |
| ≥ 2 `ListView.builder` từ API | Sản phẩm, đơn hàng, giỏ hàng, đánh giá, yêu thích, theo dõi, phản ánh, sản phẩm của tôi, các bước truy xuất |
| `Form` + `validator`, chặn gửi khi sai | Tra cứu, đăng nhập, đăng ký, đặt hàng, đánh giá (ô chọn sao là `FormField`), phản ánh, hồ sơ, sản phẩm. Quy tắc trong `utils/kiem_tra.dart`, khớp backend |
| `Scaffold` + NavigationBar | `KhungChinh`, bộ tab theo vai trò |
| Xác nhận xóa + SnackBar Hoàn tác | Xóa khỏi giỏ (hộp thoại + Hoàn tác); bỏ yêu thích/theo dõi (Hoàn tác); hủy đơn, đã nhận, đăng xuất có hộp thoại |
| Tải / dữ liệu / lỗi | Mọi màn hình gọi API có `CircularProgressIndicator`, dữ liệu, khối lỗi + Thử lại (`TrangThaiLoi`), trạng thái rỗng |
| Ảnh URL có `loadingBuilder`, `errorBuilder` | `widgets/anh_mang.dart` dùng cho mọi ảnh mạng |
| Kiểm tra `mounted` sau `await` | Mọi màn hình (`if (!mounted) return;`, hàm ngoài State dùng `context.mounted`) |
| `flutter analyze` không lỗi | Xem kết quả kiểm thử bên dưới |

**Tải ảnh:** `POST /tai-len/anh` gửi byte ảnh (`ApiClient.postBytes`). Khi backend chưa cấu hình kho ảnh (503 `CHUA_CAU_HINH_LUU_ANH`), màn hình đánh giá/phản ánh báo rõ và vẫn cho gửi không ảnh; form hồ sơ/sản phẩm cho dán URL ảnh.

**Gói thêm:** `image_picker` (chụp/chọn ảnh thật), `mobile_scanner` (quét QR). `AndroidManifest.xml` khai báo quyền `CAMERA` (camera không bắt buộc với thiết bị).

## Chạy

Cần Flutter 3.35+ (đã thử với 3.47.9) và Android SDK. Backend chạy trên máy (xem [backend/README](../backend/README.md)), app mặc định gọi `http://10.0.2.2:3000` khi chạy trên máy ảo Android.

```bash
flutter pub get
```

```bash
flutter run
```

Điện thoại thật cùng Wi-Fi:

```bash
flutter run --dart-define=API_BASE_URL=http://<IP-máy-tính>:3000
```

Mã truy xuất mẫu để thử: chạy `SELECT ma_truy_xuat FROM lo_san_xuat LIMIT 5;` trên CSDL, hoặc đăng nhập `khach1` và mở một đơn: mỗi dòng đơn có mã lô. Mã được sinh ngẫu nhiên mỗi lần chạy seed.

Tài khoản mẫu (mật khẩu `Demo@12345`, chỉ có trong dữ liệu seed):
- `khach1@ocop.example` … `khach5@ocop.example`: khách; `khach1` có giỏ sẵn, đơn `DA_GIAO` và `DA_NHAN`;
- `ncc1@ocop.example`: nhà cung cấp có hồ sơ đã duyệt và 5 sản phẩm;
- `ncc11@ocop.example`: nhà cung cấp có hồ sơ đang chờ duyệt.

## Build APK release để nộp

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://ocop-backend.onrender.com
```

APK nằm ở `build/app/outputs/flutter-apk/app-release.apk`.

Khóa ký:
- Khi chưa có khóa riêng, bản release tạm ký bằng khóa debug, vẫn cài được để demo.
- Để ký bằng khóa của nhóm, tạo `android/key.properties` (không commit) với các trường `storeFile`, `storePassword`, `keyAlias`, `keyPassword`, giống app Admin.

## Kiểm thử

```bash
flutter analyze
```

```bash
flutter test
```

`test/kien_truc_test.dart` kiểm tra kiến trúc bằng cách đọc `import` trong `lib/`. Ví dụ: màn hình không dùng thẳng `package:http`, chỉ `token_store.dart` dùng `shared_preferences`, `models/` không dùng Flutter. Xem [Architecture](../docs/development/Architecture.md#kiểm-tra-kiến-trúc-hai-app-bằng-máy).

Các file test:
- `test/du_lieu_test.dart`: `fromJson` của mọi model (JSON chép từ backend thật), validator, `ApiClient` (POST JSON, tải byte ảnh, 401 khi có/không có token, lỗi kèm chi tiết) và repository;
- `test/man_hinh_test.dart`: widget test với `MockClient` (máy chủ giả trong `test/may_chu_gia.dart`) cho đăng nhập (chặn form sai, trả kết quả), giỏ hàng (xác nhận xóa + Hoàn tác), đặt hàng (chặn form sai, không gửi `cacDong`, trả đơn), đơn hàng (lọc, hủy, đã nhận rồi đánh giá), đánh giá, phản ánh, chi tiết sản phẩm khi chưa đăng nhập (mở đăng nhập rồi quay lại thêm giỏ), hồ sơ và sản phẩm nhà cung cấp, bộ tab theo vai trò, hết phiên;
- `test/widget_test.dart`, `test/don_vi_test.dart`: test cũ của màn hình sản phẩm, tra cứu, `ApiClient`.

`test/api_backend_test.dart` gọi backend **thật** và tự bỏ qua nếu chưa đặt biến môi trường. Test chỉ đọc dữ liệu mẫu: đăng nhập `khach1` rồi đọc giỏ, đơn, chi tiết đơn, mã lô trong đơn, yêu thích, theo dõi, phản ánh; `khach1` gọi API nhà cung cấp bị 403; tải ảnh trả URL hoặc 503; token giả bị 401 và bị xóa; `ncc1` (hồ sơ đã duyệt) và `ncc11` (chờ duyệt) đọc hồ sơ, sản phẩm của mình. Muốn chạy (mã lô lấy từ `GET /don-hang/:id` hoặc CSDL):

```bash
OCOP_API_TEST_URL=http://localhost:3000 OCOP_MA_LO_TEST=<mã lô> flutter test test/api_backend_test.dart
```

**Lần kiểm tra gần nhất:**
- `flutter analyze`: No issues found;
- `flutter test`: 52 test đạt, 8 contract test bỏ qua khi chưa đặt biến môi trường;
- contract test với backend cục bộ (dữ liệu mẫu): 8/8 đạt;
- `flutter build apk --release --dart-define=API_BASE_URL=https://ocop-backend.onrender.com`: thành công (khoảng 71 MB, vì `mobile_scanner` kèm mô hình đọc mã của ML Kit cho mọi kiến trúc CPU; có thể dùng `--split-per-abi` để có APK nhỏ hơn cho từng loại máy).

**Chưa chạy thử giao diện trên máy ảo hoặc điện thoại thật** (camera quét QR và chọn ảnh chỉ kiểm tra được trên thiết bị). Backend cục bộ chưa cấu hình Supabase Storage nên mới thử nhánh 503 của tải ảnh.
