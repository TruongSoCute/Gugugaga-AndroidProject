# Kiến trúc mã nguồn

Nguồn và cách phân biệt yêu cầu: xem [README](../README.md).

**Đề xuất.** Đề không quy định kiến trúc mã nguồn; đây là lựa chọn của nhóm và cần cả nhóm thống nhất. Backend và hai app đã theo kiến trúc này, và quy tắc phụ thuộc được **kiểm tra bằng máy** (backend trong `npm test`, app Admin bằng ArchUnit, app Client bằng `flutter test`).

Cài đặt và chạy: [Setup](Setup.md). Quy trình làm việc nhóm: [Contributing](Contributing.md).

## Tổng quan hệ thống

Phần này là **Bắt buộc** theo phần B của đề: công nghệ, nơi chạy và việc hai app dùng chung một backend và một CSDL.

```mermaid
flowchart LR
  subgraph DT["Điện thoại Android"]
    A["App Admin<br/>Java/XML · Retrofit"]
    C["App Client<br/>Flutter · http"]
  end
  Q["Camera / trình duyệt<br/>quét QR trên bao bì"]
  subgraph R["Render (Frankfurt)"]
    B["Backend REST API<br/>Node 20 · Express 4 · pg"]
  end
  subgraph S["Supabase (eu-west-1)"]
    D[("PostgreSQL<br/>16 bảng, RLS bật")]
    ST["Storage ảnh<br/>(chưa dùng)"]
  end
  A -- "HTTPS + JWT" --> B
  C -- "HTTPS + JWT (trừ API công khai)" --> B
  Q -- "GET /truy-xuat/:ma (không cần JWT)" --> B
  B -- "Session pooler :5432, SSL" --> D
  B -. "upload ảnh (dự kiến)" .-> ST
```

| Thành phần | Công nghệ | Chạy ở đâu | Thư mục |
| --- | --- | --- | --- |
| App Admin cho quản trị và nhân viên | Android Studio, Java, XML, minSdk 24, Retrofit 2 + Gson | Điện thoại hoặc máy ảo Android | `admin-android/` |
| App Client cho khách | Flutter 3.35+, Dart 3, gói `http`, `shared_preferences` | Điện thoại hoặc máy ảo Android | `client-flutter/` |
| Backend REST API | Node.js 20, Express 4, `pg` (SQL thuần), `jsonwebtoken`, `bcryptjs` | Render Web Service gói Free: https://ocop-backend.onrender.com | `backend/` |
| CSDL | PostgreSQL trên Supabase gói Free | Supabase project `Gugugaga-Android` | `backend/db/` |

Nguyên tắc chung:

- **Hai app không bao giờ kết nối thẳng vào Supabase** và không chứa khóa Supabase nào. Mọi dữ liệu đi qua backend.
- **Backend là nơi duy nhất quyết định** quyền, giá, trạng thái và tính hợp lệ. App chỉ hiển thị, và ẩn nút cho đẹp; backend vẫn chặn bằng 401/403/409.
- **Mọi bảng bật RLS mà không có policy**, nên REST API tự động của Supabase không đọc hay ghi được gì. Backend kết nối bằng chủ sở hữu bảng nên không bị chặn.
- **Bí mật** (`DATABASE_URL`, `JWT_SECRET`) chỉ nằm trong biến môi trường của Render, hoặc trong `backend/.env` trên máy cá nhân (không commit).
- **Mỗi lô có mã truy xuất** 20 ký tự hex, sinh từ 80 bit ngẫu nhiên. QR in đường dẫn `https://ocop-backend.onrender.com/truy-xuat/<mã>`. App Client tách mã từ đường dẫn rồi gọi API công khai.

### Đường đi của một yêu cầu

Ví dụ: khách bấm "Đặt hàng" trên app Client. Phần backend trong sơ đồ đã có thật; phía app (`DonHangRepository`, hàm `post` của `ApiClient`, xử lý 401) là **dự kiến**, sẽ thêm khi làm màn hình giỏ hàng và đăng nhập.

```mermaid
sequenceDiagram
  participant M as Màn hình (Flutter)
  participant RP as DonHangRepository (dự kiến)
  participant AC as ApiClient
  participant RT as routes.js
  participant SV as service.js
  participant RE as repo.js
  participant DB as PostgreSQL
  M->>RP: datHang(...)
  RP->>AC: post('/don-hang', body)
  AC->>RT: HTTPS, header Authorization: Bearer + JWT
  RT->>RT: auth.khach: kiểm tra JWT, đọc lại vai trò trong CSDL
  RT->>RT: types.parseDatHang: chỉ nhận trường khai báo, sai thì 400
  RT->>SV: datHang(khachId, d)
  SV->>DB: BEGIN
  SV->>RE: khoaLoConBan (SELECT … FOR UPDATE)
  SV->>SV: chia lô FIFO, tính tiền và phí giao
  SV->>RE: themDon, themChiTiet, truTonLo, themLichSu
  SV->>DB: COMMIT (lỗi thì ROLLBACK)
  RT-->>AC: 201 + JSON đơn hàng
  AC-->>M: model, hoặc ApiException (lỗi mạng / mã HTTP + thông điệp)
```

### Bản đồ miền nghiệp vụ

| Miền (`backend/src/domains/`) | Đường dẫn API | Bảng chính | Trạng thái |
| --- | --- | --- | --- |
| `he-thong` | `/health` | — | Xong |
| `tai-khoan` | `/auth` | `nguoi_dung` | Xong: đăng ký, đăng nhập, `GET /auth/toi` |
| `danh-muc` | `/vung-nguyen-lieu` | `vung_nguyen_lieu` | Xong |
| `nha-cung-cap` | `/nha-cung-cap`, `/quan-tri/nha-cung-cap` | `nha_cung_cap`, `chung_nhan` | Xong: nhập hồ sơ, duyệt |
| `san-pham` | `/san-pham`, `/quan-tri/san-pham` | `san_pham` | Xong: danh sách, lọc, duyệt, chốt hạng sao |
| `truy-xuat` | `/lo-san-xuat`, `/truy-xuat/:ma` | `lo_san_xuat`, `buoc_truy_xuat` | Xong: lô, bước, QR công khai |
| `don-hang` | `/gio-hang`, `/don-hang`, `/quan-tri/don-hang` | `gio_hang`, `don_hang`, `chi_tiet_don`, `lich_su_trang_thai_don` | Xong: giỏ, đặt đơn FIFO, chuyển trạng thái |
| *(chưa có)* | đánh giá, phản ánh | `danh_gia`, `anh_danh_gia`, `bao_cao_vi_pham` | Bảng đã có, chưa có API |
| *(chưa có)* | yêu thích, theo dõi | `yeu_thich`, `theo_doi_nha_cung_cap` | Bảng đã có, chưa có API |
| *(chưa có)* | báo cáo doanh số | đọc từ `don_hang`, `chi_tiet_don`, `lo_san_xuat` | Chưa làm |
| *(chưa có)* | upload ảnh | Supabase Storage | Chưa làm; hiện dùng URL ảnh |

Chi tiết từng endpoint: [API](API.md). Bảng và quan hệ: [Data model](Data_model.md). Quy tắc nghiệp vụ đang áp dụng: [Design decisions](Design_decisions.md).

## Backend: miền nghiệp vụ phân tầng

Backend chia theo **miền nghiệp vụ** (`backend/src/domains/<miền>/`). Trong mỗi miền, code chỉ phụ thuộc theo một chiều:

```
types → config → repo → service → routes → index
```

Các mối quan tâm xuyên suốt (CSDL, JWT/vai trò, bcrypt, sinh số ngẫu nhiên, log, xử lý lỗi HTTP) chỉ đi vào qua một cửa là `providers/`. Hàm thuần dùng chung nằm trong `utils/`. `app.js` (App Wiring) tạo Providers, ghép các miền và gắn đường dẫn.

```
backend/src/
  app.js, server.js, config.js   App Wiring
  providers/   db (pg, transaction), auth (JWT, vai trò), password (bcrypt),
               random (crypto), logger, http (lỗi, 404)
  utils/       errors, validator, sql, http
  domains/
    he-thong/  tai-khoan/  danh-muc/  nha-cung-cap/  san-pham/  truy-xuat/  don-hang/
      types.js  [config.js]  repo.js  service.js  routes.js  index.js
backend/db/      schema.sql (tạo bảng, ràng buộc, RLS), seed.sql (dữ liệu mẫu giả lập)
backend/scripts/ db-reset.js, check-architecture.js
backend/test/    node:test, chạy với PostgreSQL thật; mỗi file tạo lại CSDL test
```

Miền `don-hang` là mẫu đầy đủ nhất để tham khảo khi viết miền mới: có `config.js` (phí giao), transaction nhiều bước, khóa dòng `FOR UPDATE`, phân quyền theo vai trò ngay trong service, và test cho cả trường hợp đặt đơn đồng thời.

| Tầng | Chứa gì | Được dùng |
| --- | --- | --- |
| `types` | Kiểm tra dữ liệu vào, hằng trạng thái; hàm thuần | `utils` |
| `config` | Cấu hình riêng của miền, nếu có (tùy chọn) | `types`, `utils` |
| `repo` | Chỉ câu SQL tham số hóa `$1, $2…`; nhận `q` là pool hoặc client transaction | `types`, `config`, `utils` |
| `service` | Quy tắc nghiệp vụ, transaction (`db.withTransaction`), lỗi 404/409 | tầng trước, `utils`, `providers` |
| `routes` | Runtime + UI của backend: đọc request, gắn quyền (`auth.nhanSu`, `auth.quanTri`), gọi service, trả JSON | `types`, `service`, `utils`, `providers`, `express` |
| `index` | Tạo service và router cho `app.js` | các tầng trong miền, `providers` |

## Quy tắc bắt buộc với code backend

`backend/scripts/check-architecture.js` kiểm tra các quy tắc sau. Mỗi quy tắc có mã lỗi tương ứng.

1. Trong một miền, mỗi tầng chỉ được require tầng **đứng trước** nó (`TANG_NGUOC`).
2. `routes` không require `repo`; truy cập dữ liệu phải qua `service` (`ROUTES_GOI_REPO`).
3. Chỉ `service`, `routes` và `index` được dùng `providers`; `types`, `config` và `repo` thì không (`PROVIDER_SAI_TANG`).
4. Miền không require miền khác. Nếu cần service của miền khác, truyền nó vào ở `app.js` (`LIEN_MIEN`). Miền cũng không require App Wiring (`MIEN_GOI_WIRING`).
5. `utils` chỉ require `utils` và không dùng thư viện nào (`UTILS_PHU_THUOC`). `providers` chỉ require `providers` và `utils` (`PROVIDER_PHU_THUOC`).
6. `pg` chỉ dùng trong `providers/db.js`, `jsonwebtoken` trong `providers/auth.js`, `bcryptjs` trong `providers/password.js`, `crypto` trong `providers/random.js`. Trong miền, chỉ `routes` được dùng `express`; không dùng thư viện ngoài nào khác (`THU_VIEN_SAI_CHO`).
7. Không `require` động, không dùng `import`/`export` ES module (`REQUIRE_DONG`, `IMPORT_ES`). Không require file ngoài `src` (`NGOAI_SRC`).
8. Mọi file `.js` trong `src` phải thuộc một vị trí ở trên; tên file trong miền chỉ là `types`, `config`, `repo`, `service`, `routes` hoặc `index` (`TEP_NGOAI_KIEN_TRUC`).

Chạy riêng phần kiểm tra này (không cần CSDL):

```bash
cd backend && npm run check:arch
```

Khi gặp vi phạm, **sửa code cho đúng tầng**. Không nới quy tắc, không sửa script kiểm tra và không thêm ngoại lệ để vượt qua. Muốn đổi quy tắc thì cả nhóm phải thống nhất trước, rồi cập nhật cùng lúc tài liệu này, `check-architecture.js` và `test/kien-truc.test.js`.

## Cách thêm hoặc sửa chức năng backend

1. Xác định chức năng thuộc miền nào. Miền mới (ví dụ `danh-gia`) thì tạo thư mục `domains/danh-gia/`. Có thể sao chép cấu trúc miền `don-hang` làm khung.
2. Viết từ tầng trước ra tầng sau:
   - `types.js`: hàm `parse...` kiểm tra body/query bằng `utils/validator`; chỉ nhận trường được khai báo, nên trường lạ như `vaiTro` hay `trangThai` do client gửi bị bỏ qua. Các hàm thuần của nghiệp vụ (ví dụ `chiaLoFifo`, `kiemTraChuyen` của miền đơn hàng) cũng đặt ở đây.
   - `config.js` (tùy chọn): hằng cấu hình riêng của miền, ví dụ bảng phí giao.
   - `repo.js`: mỗi câu SQL là một hàm `(q, ...)`, luôn dùng tham số `$n`.
   - `service.js`: `module.exports = function createXService({ db, ... }, deps)`. Kiểm tra quy tắc nghiệp vụ và dùng `db.withTransaction` khi nhiều thay đổi phải cùng thành công.
   - `routes.js`: đọc request, gọi `parse...`, gắn quyền, gọi service, trả JSON với mã HTTP phù hợp.
   - `index.js`: tạo service và router.
3. Ghép trong `app.js`. Nếu miền cần service của miền khác, truyền vào qua tham số `deps`.
4. Thêm test trong `backend/test/` cho các trường hợp thành công, sai quyền, dữ liệu không hợp lệ và không tìm thấy. Chạy `npm test`; lệnh này đã gồm kiểm tra kiến trúc.
5. Cập nhật [API](API.md) và các tài liệu liên quan cho khớp hành vi thực tế.

## Lý do áp dụng

- Miền đơn hàng có nhiều quy tắc: khóa dòng, trừ tồn, gán lô, chuyển trạng thái. Tách `repo`/`service` giúp code dễ đọc và dễ kiểm thử.
- Mỗi thành viên phụ trách một miền, nên ít xung đột merge và mỗi người có commit rõ ràng.
- Khi bảo vệ, dễ trả lời câu hỏi: SQL nằm ở `repo`, quy tắc nghiệp vụ ở `service`, quyền ở `providers/auth` và nơi gắn quyền trong `routes`.
- Kiểm tra bằng máy giữ cho code do nhiều người và AI viết vẫn theo cùng một quy tắc.

## Hai app (Đề xuất)

Hai app không quyết định nghiệp vụ, vì backend kiểm tra mọi quyền và trạng thái. Do đó app không cần tầng service.

- **Android Java/XML:** làm theo kỹ thuật đã học trong lab, xem [Labs Android](Labs_Android.md).
  - **Màn hình:** một `MainActivity` chứa các Fragment và `BottomNavigationView` (A8). Chi tiết mở bằng `newInstance` + arguments và `addToBackStack`. Fragment trao đổi kết quả qua Fragment Result API.
  - **Thư mục:** `model/` (lớp dữ liệu, tiền dùng `int`), `data/` (`ApiService` Retrofit, `ApiClient`, `TokenStore`, các repository mỏng bọc `ApiService`), `ui/<miền>/` (Fragment, Adapter RecyclerView + ViewHolder).
  - **Providers của app:** `ApiClient` (interceptor gắn token, timeout 90 giây) và `TokenStore` (`SharedPreferences`) theo Phụ lục 2. Nhận 401 thì đăng xuất về màn hình đăng nhập.
  - **Gọi API:** Fragment/Activity gọi qua repository, xử lý đủ đang tải / thành công / lỗi mạng.
  - **ViewModel:** C.1 không bắt buộc. Lab A2 giới thiệu ViewModel là thứ "sẽ dùng ở đồ án", còn A8 dùng để giữ trạng thái tab. Đề xuất: dùng ViewModel giữ danh sách tải từ API để khỏi gọi lại khi xoay; dữ liệu form đang nhập dở vẫn lưu bằng Bundle (`onSaveInstanceState`), vì ViewModel mất khi tiến trình bị hủy.
- **Flutter:** `lib/data/` (`ApiClient` dùng chung, `TokenStore` trên `shared_preferences`, các `*_repository.dart`), `models/`, `screens/`, `widgets/`, `utils/`. Màn hình không gọi `http`/`dio` trực tiếp mà qua repository.

### Các lớp chính đang có trong hai app

**App Admin** (`admin-android/app/src/main/java/vn/edu/vhu/ltdd/gugugaga/admin/`):

```
AppConfig.java            TAG "GUGUGAGA_ADMIN", API_BASE_URL (từ BuildConfig), hằng vai trò/trạng thái
data/
  ApiService.java         interface Retrofit: @GET/@POST/@PATCH từng endpoint
  ApiClient.java          một Retrofit duy nhất; interceptor gắn "Bearer <token>"; timeout 90 giây
  TokenStore.java         nơi DUY NHẤT đọc/ghi SharedPreferences (token, vai trò, họ tên)
  GoiApi.java             gọi enqueue, chia kết quả: thành công / lỗi / hết phiên (401) / lỗi mạng
  KetQuaApi.java          callback trả về cho repository/ViewModel
  AuthRepository.java, SanPhamRepository.java   repository mỏng bọc ApiService
model/                    lớp dữ liệu khớp JSON (SanPham, NguoiDung, DanhSach<T>, PhanTrang, LoiApi…)
ui/
  MainActivity.java       BottomNavigationView + các Fragment tab
  chung/TrangThai.java    trạng thái màn hình: DANG_TAI / THANH_CONG / LOI / HET_PHIEN
  chung/SuKien.java       sự kiện dùng một lần (Toast, điều hướng) qua LiveData
  dangnhap/               LoginActivity + DangNhapViewModel
  sanpham/                SanPhamFragment + SanPhamViewModel + SanPhamAdapter + 2 DialogFragment duyệt/từ chối
  taikhoan/               TaiKhoanFragment (thông tin phiên, đăng xuất)
util/DinhDang.java        định dạng tiền, ngày (Java thuần)
```

Địa chỉ API chọn theo bản build trong `app/build.gradle.kts`: debug đọc `ocopApiBaseUrlDebug`, release đọc `ocopApiBaseUrlRelease` trong `gradle.properties`. Có thể ghi đè bằng `~/.gradle/gradle.properties` mà không sửa repo (xem [Setup](Setup.md#53-trỏ-app-tới-backend-đã-deploy)).

**App Client** (`client-flutter/lib/`):

```
main.dart                 MaterialApp, theme
config.dart               TAG "GUGUGAGA_CLIENT", API_BASE_URL (--dart-define), timeout 90 giây
data/
  api_client.dart         nơi DUY NHẤT dùng package:http; hiện có get(); ném ApiException (maHttp, thongDiep; maHttp null = lỗi mạng)
  token_store.dart        nơi DUY NHẤT dùng shared_preferences
  san_pham_repository.dart, truy_xuat_repository.dart
models/                   san_pham.dart, vung.dart, hanh_trinh_lo.dart (fromJson)
screens/
  khung_chinh.dart        Scaffold + NavigationBar
  san_pham_screen.dart    lọc theo vùng, hạng sao; ListView.builder
  tra_cuu_screen.dart     Form + validator nhập/dán mã truy xuất
  hanh_trinh_screen.dart  hành trình của đúng một lô
widgets/                  anh_mang.dart (loadingBuilder/errorBuilder), trang_thai_loi.dart (lỗi + Thử lại)
utils/                    dinh_dang.dart
```

### Kiểm tra kiến trúc hai app bằng máy

Quy tắc của hai app cũng được kiểm tra tự động, giống backend. Khi bị đỏ, **sửa code cho đúng tầng**. Không nới quy tắc hay thêm ngoại lệ khi nhóm chưa thống nhất. Muốn đổi quy tắc thì cập nhật cùng lúc tài liệu này và file kiểm tra.

**Admin Android:** dùng ArchUnit. File kiểm tra là `admin-android/app/src/test/java/.../kientruc/KienTrucTest.java`, chạy bằng `./gradlew testDebugUnitTest`.

| Quy tắc | Nội dung |
| --- | --- |
| `PHAN_TANG` | `ui → data → model`; `util` dùng chung; không tầng nào phụ thuộc ngược lên `ui`. |
| `UI_CHI_DUNG_REPOSITORY` | `ui` chỉ dùng `*Repository`, `KetQuaApi`, `TokenStore` của tầng data; không dùng thẳng `ApiClient`/`ApiService`/`GoiApi`. |
| `HTTP_CHI_O_DATA`, `GSON_CHI_O_DATA` | Retrofit, OkHttp, Gson chỉ ở tầng data. Model được dùng annotation `@SerializedName`. |
| `SHARED_PREFS_CHI_O_TOKEN_STORE` | Chỉ `TokenStore` đọc/ghi `SharedPreferences`. |
| `MODEL_THUAN`, `UTIL_THUAN` | Model và util chỉ dùng Java thuần (model được dùng annotation Gson). |
| `DATA_KHONG_DUNG_GIAO_DIEN` | Tầng data không phụ thuộc View, Fragment, AppCompat, Material, Lifecycle. |
| `KHONG_GOI_MANG_DONG_BO` | Không gọi `Call.execute()`, chỉ dùng `enqueue` (Lab A2: gọi đồng bộ trên main thread gây ANR). |
| `FRAGMENT_CONSTRUCTOR_RONG` | Fragment chỉ có constructor rỗng; dữ liệu truyền bằng `newInstance` + arguments (Lab A8). |
| `VIEWMODEL_KHONG_GIU_GIAO_DIEN` | ViewModel không giữ View, Activity, Fragment, để tránh rò rỉ bộ nhớ. |
| `KHONG_SYSTEM_OUT`, `KHONG_JAVA_UTIL_LOGGING` | Ghi log bằng `android.util.Log` với `TAG` (Lab A1). |

`KienTrucTuKiemTest` áp các quy tắc lên một lớp ví dụ sai trong thư mục test, để chứng minh quy tắc bắt được vi phạm thật.

**Client Flutter:** Dart không có ArchUnit, nên dùng `client-flutter/test/kien_truc_test.dart`. Test này đọc các dòng `import` trong `lib/`, chạy bằng `flutter test`, và báo lỗi khi:
- `models/` và `utils/` dùng Flutter hoặc import tầng khác;
- `widgets/` import `data/`;
- `data/` import giao diện;
- `package:http`/`dio` và `dart:io` dùng ngoài `data/api_client.dart`;
- `shared_preferences` dùng ngoài `data/token_store.dart`;
- có file nằm ngoài các thư mục quy định.

Test cũng có một trường hợp ví dụ sai để chứng minh bộ kiểm tra hoạt động.

