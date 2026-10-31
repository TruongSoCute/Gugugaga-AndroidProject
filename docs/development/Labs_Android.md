# Kiến thức lab áp dụng cho app Admin Android

Nguồn và cách phân biệt yêu cầu: xem [README](../README.md).

Mục C.1 của đề ghi mỗi yêu cầu của app Admin lấy kiến thức từ lab nào, và app Admin được chấm 2,0 điểm theo đủ 10 yêu cầu đó. Vì vậy app Admin nên dùng đúng kỹ thuật và quy ước giảng viên đã dạy trong lab, không dùng cách khác khi lab đã có cách làm.

Tài liệu này tổng hợp từ:
- slide **Lab A1–A9**: môi trường và vòng đời, lưu trạng thái và Git, XML layout và tài nguyên, sự kiện và kiểm tra dữ liệu nhập, Intent, control lựa chọn, quyền, Fragment, Adapter;
- **mục C.1** và **Phụ lục 2** (gọi API bằng Retrofit) của tài liệu đồ án.

Các mục ghi **Quy ước lab** là cách làm giảng viên dạy và chấm trong lab. Các mục ghi **Áp dụng cho đề 5 (Đề xuất)** là cách nhóm dự định dùng, chưa phải yêu cầu chính thức.

## Đối chiếu yêu cầu C.1 với lab

Lab A10–A15 và F1–F8 chưa có slide trong repo. Các dòng ghi "chưa có slide" cần bổ sung khi có tài liệu.

| # | Yêu cầu C.1 (bắt buộc) | Lab theo đề | Nguồn đang có | Áp dụng cho đề 5 (Đề xuất) |
| --- | --- | --- | --- | --- |
| 1 | Đăng nhập, lưu token, tự đăng xuất khi token hết hạn | A5, A7 | A5 (chuyển màn hình). Slide A7 dạy quyền truy cập, không nói về token. Cách lưu token lấy theo **Phụ lục 2**: `SharedPreferences` + interceptor | `LoginActivity` gọi `POST /auth/dang-nhap`, lưu `token` và `vaiTro`; nhận 401 thì xóa token và về màn hình đăng nhập |
| 2 | Ít nhất 2 vai trò thấy chức năng khác nhau | A8 | A8 | `QUAN_TRI` thấy thêm nút Duyệt/Từ chối và tab Báo cáo; `NHAN_VIEN` nhập liệu, quản lý lô, đơn và phản ánh (theo [Design decisions](Design_decisions.md)). Backend vẫn chặn bằng 403 |
| 3 | ≥ 2 danh sách RecyclerView + Adapter + ViewHolder | A9, A10 | A9 (Adapter, ViewHolder với ListView). A10 (RecyclerView) chưa có slide | Danh sách hồ sơ chờ duyệt, sản phẩm, lô, đơn hàng, phản ánh. **Phải dùng RecyclerView**, không dùng ListView |
| 4 | Nhiều màn hình bằng Fragment hoặc nhiều Activity | A5, A8 | A5, A8 | Một `MainActivity` + Fragment cho từng tab; màn hình chi tiết mở bằng Fragment có back stack |
| 5 | Form kiểm tra hợp lệ, báo lỗi đúng chỗ | A4, A6 | A4 (bốn lớp kiểm tra, `try-catch`), A6 (thứ tự kiểm tra, control lựa chọn) | Form tạo lô, thêm bước truy xuất, nhập nhà cung cấp/sản phẩm, lý do từ chối |
| 6 | Hộp thoại xác nhận trước khi xóa; Toast/Snackbar báo kết quả | A11 | Chưa có slide (A7 có ví dụ `AlertDialog.Builder`) | Xác nhận trước khi từ chối hồ sơ, hủy đơn, xóa |
| 7 | ≥ 1 màn hình báo cáo có biểu đồ (MPAndroidChart hoặc tự vẽ) | A9–A12 | Chưa có slide về biểu đồ | Doanh số theo vùng, theo hạng sao, nhà cung cấp bán tốt nhất |
| 8 | Đủ 3 trạng thái khi gọi API: đang tải / thành công / lỗi mạng | A7, A14 | **Phụ lục 2 mục 2.4** (A14 chưa có slide) | Mọi màn hình gọi API có `ProgressBar`, danh sách rỗng và thông báo lỗi |
| 9 | Không mất dữ liệu form khi xoay màn hình | A2 | A2 (`onSaveInstanceState`, Bundle); A5, A6, A8 nhắc lại | Form tạo lô và form từ chối giữ dữ liệu khi xoay; thử thêm với "Don't keep activities" |
| 10 | Tên app và TAG log chứa mã nhóm | A1 | A1 (TAG = mã lab + MSSV để lọc Logcat và chứng minh bài làm) | `OCOP Admin Gugugaga`, `vn.edu.vhu.ltdd.gugugaga.admin`, `TAG = "GUGUGAGA_ADMIN"` |

## Gọi API: Phụ lục 2 (bắt buộc tự học, chưa có lab)

**Quy ước của tài liệu đồ án:**
- **Thư viện:** `retrofit:2.11.0`, `converter-gson:2.11.0`, `logging-interceptor:4.12.0`. Manifest khai báo `<uses-permission android:name="android.permission.INTERNET" />`.
- **Lớp dữ liệu:** tên trường khớp tên trong JSON; trường nào khác tên thì dùng `@SerializedName`.
- **`interface ApiService`:** khai báo từng endpoint bằng `@GET`, `@POST`, `@PATCH` cùng `@Body`, `@Query`, `@Path`.
- **`ApiClient`:**
  - giữ một instance `Retrofit` duy nhất;
  - có `OkHttpClient` với interceptor gắn header `Authorization: Bearer <token>`, token đọc từ `TokenStore` (`SharedPreferences`);
  - `connectTimeout` và `readTimeout` đặt **90 giây**, vì Render gói Free mất tới một phút để thức dậy.
- **Gọi API bằng `enqueue`, đủ các nhánh:**
  - trước khi gọi: hiện `ProgressBar`;
  - `onResponse` thành công: ẩn `ProgressBar`, cập nhật dữ liệu, gọi `notify...` cho adapter, hiện ô "trống" nếu không có dữ liệu;
  - `onResponse` mã 401: đăng xuất và về màn hình đăng nhập;
  - `onResponse` mã khác: báo lỗi máy chủ;
  - `onFailure`: báo "Không kết nối được máy chủ".
- **Bốn lỗi hay gặp:**
  - quên quyền `INTERNET`;
  - `BASE_URL` thiếu dấu `/` ở cuối;
  - dùng `http://` (từ Android 9 bị chặn mặc định);
  - timeout quá ngắn.

**Áp dụng cho đề 5 (Đề xuất):**
- **JSON khớp sẵn:** backend trả khóa camelCase (`hoTen`, `vaiTro`, `maTruyXuat`), nên trường Java đặt cùng tên là Gson tự khớp, gần như không cần `@SerializedName`.
- **Lỗi từ backend** có dạng `{ "loi": { "ma", "thongDiep", "chiTiet" } }`. App hiển thị `thongDiep`. Với lỗi 400 có `chiTiet[].truong`, app có thể `setError` đúng ô nhập tương ứng. Danh sách mã lỗi xem [API](API.md).
- **401** (thiếu, sai hoặc hết hạn token) là căn cứ để "tự đăng xuất khi token hết hạn" theo C.1 #1. Token hết hạn sau 8 giờ (`JWT_EXPIRES_IN`).
- **Gọi API qua repository:** theo [Architecture](Architecture.md), Fragment/Activity gọi API qua một lớp repository mỏng bọc `ApiService`. Callback vẫn xử lý đủ các nhánh như mục 2.4.
- **Thử với backend chạy trên máy:** máy ảo gọi `http://10.0.2.2:3000/`. Kết nối `http://` bị chặn mặc định, nên chỉ cho phép trong bản debug (network security config). Bản release luôn dùng `https://` của Render.

## Lab A1: Android Studio và vòng đời Activity

**Quy ước lab:**
- **Tạo project:**
  - template **Empty Views Activity**, vì đây là bản dùng XML; "Empty Activity" là Jetpack Compose, không dùng;
  - ngôn ngữ **Java**, Minimum SDK **API 24**, file Gradle dùng Kotlin DSL (code app vẫn là Java);
  - đường dẫn project và SDK không có dấu tiếng Việt hoặc khoảng trắng.
- **Cấu trúc project:**
  - `AndroidManifest.xml` khai báo Activity khởi chạy (MAIN/LAUNCHER) và quyền;
  - `res/layout` chứa giao diện, `res/values/strings.xml` chứa chuỗi (không viết cứng chữ trong layout);
  - `build.gradle.kts` khai báo `minSdk` và thư viện.
- **Vòng đời Activity có 7 callback.** Ba cặp đối xứng là `onCreate/onDestroy`, `onStart/onStop` và `onResume/onPause`. Mỗi callback override phải gọi `super.onXxx()`.
- **Log:**
  - dùng `android.util.Log` với hằng `private static final String TAG`, không dùng `System.out.println`;
  - lọc Logcat bằng `tag:<TAG>` và `level:`;
  - TAG chứa mã lab + MSSV để chống sao chép.
- **Đọc lỗi:** khi app crash, tìm dòng `FATAL EXCEPTION`, đọc tên lỗi, rồi bấm vào dòng `at ...` đầu tiên thuộc package của mình. Kiểm tra `null` trước tốt hơn bắt `NullPointerException`.
- **Hai hiện tượng cần hiểu đúng:**
  - xoay màn hình là thay đổi cấu hình, nên Activity bị hủy và tạo lại, làm mất biến thành viên;
  - từ Android 12, nhấn Back ở Activity gốc chỉ đưa app xuống nền, không gọi `onDestroy`.

**Áp dụng cho đề 5 (Đề xuất):**
- **Tạo project:** project `admin-android/` theo đúng cấu hình trên.
- **Tên app, package và TAG chứa mã nhóm `gugugaga`** (đề E.4 dùng đây làm dấu hiệu đối chiếu chống sao chép):
  - tên app: `OCOP Admin Gugugaga`;
  - package theo mẫu của trường: `vn.edu.vhu.ltdd.gugugaga.admin`;
  - `TAG = "GUGUGAGA_ADMIN"`.

## Lab A2: Vòng đời có việc, lưu trạng thái và Git

**Quy ước lab:**
- **Bật/tắt theo cặp:** bật ở `onResume` thì tắt ở `onPause`, bật ở `onStart` thì tắt ở `onStop`.
- **`onPause` phải thật nhanh:** không đọc/ghi file lớn, không gọi mạng.
- **Không chặn main thread:** không dùng `while(true)` + `Thread.sleep()`, vì sau khoảng 5 giây hệ thống báo ANR.
  - Cập nhật giao diện định kỳ bằng `Handler(Looper.getMainLooper())` + `postDelayed`.
  - Gọi `removeCallbacks` ở `onPause`/`onDestroy`, và gọi trước mỗi lần `post`, để tránh rò rỉ bộ nhớ và chạy chồng.
- **Lưu trạng thái giao diện bằng `onSaveInstanceState(Bundle)`:**
  - luôn gọi `super`, nếu không các View như EditText và ScrollView không tự lưu trạng thái;
  - dùng khóa là hằng `KEY_...`;
  - khôi phục trong `onCreate` sau `setContentView` khi `savedInstanceState != null`, hoặc trong `onRestoreInstanceState`.
- **Khi nào Bundle được lưu:**
  - **có:** xoay màn hình, đổi ngôn ngữ/cỡ chữ, hệ thống thu hồi app ở nền;
  - **không:** người dùng nhấn Back, gọi `finish()`, vuốt app khỏi Recents.
- **Bundle chỉ chứa dữ liệu nhỏ** như số, chuỗi ngắn, Parcelable nhỏ. Danh sách lớn hoặc ảnh sẽ gây `TransactionTooLargeException`.
- **ViewModel:** lab giới thiệu ViewModel và ghi "sẽ dùng ở đồ án".
  - giữ dữ liệu qua xoay màn hình, không giới hạn kích thước;
  - mất khi tiến trình bị hủy, nên thường dùng kèm Bundle.
- **Thời gian:** đo khoảng thời gian bằng `SystemClock.elapsedRealtime()`, không dùng `System.currentTimeMillis()`. Lưu mốc thời gian rồi tính hiệu, không cộng dồn từng giây.
- **Kiểm thử thu hồi bộ nhớ:** bật *Tùy chọn nhà phát triển → Không giữ hoạt động* (Don't keep activities) để mô phỏng hệ thống thu hồi app.
- **Git:**
  - `.gitignore` bỏ qua `build/`, `.gradle/`, `local.properties`;
  - commit sau mỗi phần việc, thông điệp không dấu và mô tả việc đã làm;
  - repo Private thì mời giảng viên làm collaborator.

**Áp dụng cho đề 5 (Đề xuất):**
- **Dữ liệu đang nhập dở** trong form tạo lô (lựa chọn Spinner, ngày đã chọn, các bước chưa gửi) lưu bằng Bundle. EditText có `id` tự khôi phục.
- **Danh sách tải từ API** không nhét vào Bundle. Giữ trong ViewModel để khỏi gọi lại API khi xoay màn hình, hoặc tải lại.
- **Mọi lệnh gọi mạng** chạy bằng `enqueue` của Retrofit (chạy nền), không gọi trong `onPause`.
- **`.gitignore` ở gốc repo** đã có `build/`, `.gradle/`, `local.properties`.

## Lab A3: XML layout và tài nguyên

**Quy ước lab:**
- **Chọn layout:**
  - `LinearLayout` cho form và bố cục đơn giản;
  - `FrameLayout` cho các lớp chồng nhau (thẻ khai báo sau đè lên thẻ trước, đặt vị trí bằng `layout_gravity`);
  - `ConstraintLayout` cho màn hình phức tạp.
  - Layout càng phẳng càng nhanh. Lồng quá 3 tầng `LinearLayout` thì nên chuyển sang `ConstraintLayout`.
- **ConstraintLayout:** mỗi view có ít nhất một ràng buộc ngang và một ràng buộc dọc. Dùng `0dp` kèm hai ràng buộc thay cho `match_parent`.
- **Kích thước:** `dp` cho kích thước và lề, `sp` cho cỡ chữ, **không dùng `px`**. Chia không gian bằng `0dp` + `layout_weight`, đẩy phần tử về hai đầu bằng `<Space>`.
- **`padding` và `gravity`:** `padding` là đệm bên trong, `layout_margin` là khoảng cách bên ngoài. `gravity` căn nội dung, `layout_gravity` căn chính view trong cha. Dùng `paddingStart/End`, không dùng `Left/Right`.
- **Tách tài nguyên, không viết cứng:**
  - chuỗi trong `strings.xml`, màu trong `colors.xml`, kích thước trong `dimens.xml`, kiểu chung trong `themes.xml`;
  - nền bo góc hoặc chuyển màu vẽ bằng `drawable/*.xml` (`<shape>`).
  - Khi chấm, còn chuỗi tiếng Việt hoặc mã màu viết cứng trong layout là bị trừ điểm. Dùng Alt+Enter → *Extract string resource* để tách.
- **`ScrollView`** chỉ có đúng một con trực tiếp; dùng `fillViewport="true"`.
- **Ô nhập:** dùng `TextInputLayout` + `TextInputEditText`. Ô mật khẩu đặt `app:endIconMode="password_toggle"`. `setError` hiện lỗi ngay dưới ô.
- **Thẻ thông tin:** dùng `MaterialCardView`. Khối giao diện dùng lại tách thành file riêng rồi nhúng bằng `<include>`.
- **Layout theo cấu hình:** `res/layout-land` cho màn hình ngang, `layout-sw600dp` cho tablet. Giữ nguyên các `id` để không phải sửa Java.
- **Wireframe:** phác thảo ra giấy trước khi viết XML (yêu cầu của đề cương).
- **Ghi chú của giảng viên trên slide** có nhắc rubric đồ án chấm "bám chuẩn Material Design, màu sắc hài hòa" và nêu đích danh ConstraintLayout/LinearLayout. Tài liệu đồ án hiện có chưa chứa rubric chi tiết này, **cần xác nhận**.

**Áp dụng cho đề 5 (Đề xuất):**
- **Màn hình đăng nhập Admin:** `TextInputLayout` cho email (`textEmailAddress`) và mật khẩu (`password_toggle`), nút Đăng nhập rộng hết chiều ngang, toàn bộ bọc trong `ScrollView`.
- **Form tạo lô và form nhập nhà cung cấp:** bọc `ScrollView` để bàn phím không che nút Lưu.
- **Thẻ tóm tắt:** thẻ lô hoặc thẻ nhà cung cấp dùng `MaterialCardView` + `<include>` ở cả danh sách và chi tiết.
- **Tài nguyên:** màu chủ đạo và chuỗi đặt trong tài nguyên. Wireframe vẽ tay đưa vào mục "Thiết kế giao diện" của báo cáo.

## Lab A4: TextView, Button, EditText và xử lý sự kiện

**Quy ước lab:**
- **Ba bước xử lý sự kiện:**
  1. ánh xạ view bằng `findViewById` **sau** `setContentView`;
  2. gán listener một lần;
  3. xử lý trong phương thức riêng: đọc → kiểm tra → tính → hiển thị.
- **Cách gán listener:**
  - mỗi nút một việc → lambda cho từng nút;
  - nhiều nút làm việc tương tự → một listener dùng chung, phân biệt bằng `if/else` theo `v.getId()` (không dùng `switch`, vì từ AGP 8 `R.id` không còn là hằng số);
  - **tránh `android:onClick` trong XML**: gõ sai tên hàm là crash, và không dùng được với Fragment.
- **`inputType` chọn đúng bàn phím:** `textEmailAddress`, `textPassword`, `number`, `numberDecimal`, `phone`... `inputType` chỉ gợi ý bàn phím, người dùng vẫn dán được chữ, nên **vẫn phải kiểm tra trong code**.
- **Đọc dữ liệu nhập:** `getText().toString().trim()`.
- **Bốn lớp kiểm tra, theo thứ tự, gặp lỗi thì `return` ngay:**
  1. **rỗng** → `setError` + `requestFocus()`;
  2. **định dạng** → parse trong `try-catch NumberFormatException`;
  3. **miền giá trị** → số âm, bằng 0, chia cho 0...;
  4. **quy tắc nghiệp vụ**.
- **Kiểm tra ở giao diện không thay thế kiểm tra phía dữ liệu/API.**
- **Báo cho người dùng:**
  - `setError` cho lỗi thuộc một ô nhập;
  - `Toast` cho thông báo ngắn;
  - `Snackbar` khi kèm nút (ví dụ Hoàn tác);
  - `AlertDialog` khi cần xác nhận (A11).
  - Lời báo lỗi nói rõ sai ở đâu và cách sửa.
- **Định dạng số:** `String.format(Locale..., ...)`, luôn truyền `Locale`. Chia hai số nguyên thì ép sang `double` trước.
- **Nút "Xóa trắng"** đặt lại nội dung, gọi `setError(null)` và đưa con trỏ về ô đầu.
- **Quy cách mã nguồn:**
  - tên biến và phương thức có nghĩa (tiếng Việt không dấu được chấp nhận);
  - tách phương thức, không dồn toàn bộ logic vào `onCreate`.
- **Bảng test case:** mỗi dòng ghi dữ liệu nhập, kết quả mong đợi và cột Đạt/Không đạt, kèm ảnh cho các trường hợp lỗi. Nên có cả trường hợp "ác": số rất lớn, nhiều dấu chấm, khoảng trắng.

**Áp dụng cho đề 5 (Đề xuất):**
- **Bốn lớp kiểm tra cho form tạo lô:**
  1. rỗng: người sản xuất, ngày sản xuất, hạn sử dụng, số lượng;
  2. định dạng: số lượng là số nguyên, ngày hợp lệ;
  3. miền: số lượng > 0, hạn sử dụng sau ngày sản xuất;
  4. nghiệp vụ: backend kiểm tra (ví dụ sản phẩm bị từ chối trả 409), app hiển thị `loi.thongDiep`.
- **Thông báo:** dùng `Snackbar` cho kết quả thao tác và `AlertDialog` để xác nhận từ chối hoặc hủy.

## Lab A5: Chuyển màn hình và truyền dữ liệu bằng Intent

**Quy ước lab:**
- **Tạo Activity bằng *File → New → Activity*** để Android Studio tự khai báo trong `AndroidManifest.xml`. Activity không khai báo sẽ gây `ActivityNotFoundException`. Đặt tên theo vai trò: `LoginActivity`, `MainActivity`, `DetailActivity`.
- **Khóa extras là hằng số dùng chung** (`public static final String EXTRA_...`), không gõ chuỗi hai lần.
- **Luôn có giá trị mặc định** khi đọc `getIntExtra`/`getBooleanExtra`, và kiểm tra `null` cho chuỗi/đối tượng.
- **Truyền đối tượng bằng `Parcelable`**: sinh code bằng Alt+Enter; thứ tự ghi và đọc phải giống nhau.
- **Nhận kết quả bằng Activity Result API:**
  - đăng ký `registerForActivityResult` ở **cấp field**, không gọi trong `onClick` (sẽ crash "attempting to register while RESUMED");
  - xử lý cả `RESULT_OK` lẫn `RESULT_CANCELED`;
  - màn hình 2 gọi `setResult(...)` trước `finish()`;
  - không dùng `startActivityForResult` vì đã lỗi thời.
- **Intent ngầm định** (`ACTION_DIAL`, `ACTION_VIEW` với `https:`/`geo:`, `ACTION_SEND` bọc `Intent.createChooser`) phải bọc trong `try-catch ActivityNotFoundException`.
- **`onPause` phải nhẹ**, vì màn hình mới chỉ hiện sau khi `onPause` của màn hình cũ chạy xong.
- **Dữ liệu qua Intent còn nguyên khi xoay màn hình.** Dữ liệu người dùng đã sửa mà chưa lưu thì mất; muốn giữ phải dùng `onSaveInstanceState`.

**Áp dụng cho đề 5 (Đề xuất):**
- `LoginActivity` đăng nhập xong thì mở `MainActivity` và `finish()`.
- Bấm số điện thoại nhà cung cấp mở `ACTION_DIAL`, không cần quyền gọi điện.
- Mở vị trí vùng nguyên liệu bằng `geo:<viDo>,<kinhDo>`.
- Chia sẻ đường dẫn truy xuất của lô (`duongDanTruyXuat`) bằng `ACTION_SEND`.

## Lab A6: Control lựa chọn, Spinner và kiểm tra form

**Quy ước lab:**
- **Chọn control theo tình huống:**
  - chọn nhiều → `CheckBox`;
  - chọn một trong ít phương án → `RadioGroup` + `RadioButton` (RadioButton phải nằm trong RadioGroup; chưa chọn thì `getCheckedRadioButtonId() == -1`);
  - chọn một trong danh sách dài → `Spinner` + `ArrayAdapter`;
  - bật/tắt → `MaterialSwitch` (theme kế thừa `Theme.Material3`).
- **Listener của Spinner:** `OnItemSelectedListener` có hai phương thức nên không viết được bằng lambda. `onItemSelected` chạy ngay khi `setAdapter`, nên không đặt Toast trong đó.
- **Kiểm tra form:**
  - kiểm tra theo thứ tự trên màn hình; sai ở đâu thì `setError`, `requestFocus()` và `return` ngay tại đó;
  - `trim()` chuỗi trước khi kiểm tra;
  - lời báo lỗi phải nói rõ người dùng cần làm gì;
  - lựa chọn chưa chọn thì báo bằng Toast;
  - chỉ chuyển màn hình hoặc gọi API khi mọi điều kiện đều đạt.
- **Chuỗi hiển thị** đặt trong `strings.xml`, ghép bằng `getString(id, ...)` với mẫu `%1$s`.
- **Nối danh sách** bằng `TextUtils.join`, không dùng `String.join` (cần API 26, trong khi minSdk là 24).
- **Form dài phải bọc trong `ScrollView`**, nếu không máy nhỏ không bấm được nút.
- **Kiểm thử bằng cách để trống từng ô một.** EditText có `id` tự khôi phục khi xoay, biến thành viên thì mất.

**Áp dụng cho đề 5 (Đề xuất):**
- **Form tạo lô:**
  - `Spinner` sản phẩm và `Spinner` vùng nguyên liệu, nạp từ `GET /quan-tri/san-pham` và `GET /vung-nguyen-lieu` bằng `ArrayAdapter` với `List`;
  - ngày sản xuất và hạn sử dụng (hạn phải sau ngày sản xuất);
  - số lượng > 0, có bẫy `NumberFormatException`;
  - người sản xuất (bắt buộc).
- **Duyệt sản phẩm:** `RadioGroup` 3/4/5 sao.
- **Từ chối hồ sơ:** bắt buộc nhập lý do.
- Backend vẫn kiểm tra lại mọi điều kiện; app kiểm tra để báo lỗi sớm và đúng chỗ.

## Lab A7: Xin quyền lúc chạy (Runtime Permission)

**Quy ước lab:**
- **Hai loại quyền:**
  - quyền thường (`INTERNET`, `ACCESS_NETWORK_STATE`) chỉ cần khai báo trong Manifest;
  - quyền nguy hiểm (`CAMERA`, `POST_NOTIFICATIONS`, vị trí...) phải khai báo **và** xin lúc chạy.
- **Khai báo trong Manifest:** `<uses-permission>` là con trực tiếp của `<manifest>`. Với phần cứng không bắt buộc, khai báo `<uses-feature ... android:required="false" />` rồi kiểm tra trong code.
- **Mẫu ba nhánh:**
  1. đã có quyền (`checkSelfPermission`) → dùng ngay;
  2. từng bị từ chối (`shouldShowRequestPermissionRationale`) → hiện hộp thoại giải thích rồi mới hỏi lại;
  3. lần đầu → hỏi bằng launcher `ActivityResultContracts.RequestPermission`.
- **Launcher đăng ký ở cấp field.** Trong callback, nếu bị từ chối mà `shouldShowRequestPermissionRationale` vẫn là `false` thì quyền đã bị chặn vĩnh viễn → mời mở Cài đặt (`ACTION_APPLICATION_DETAILS_SETTINGS`).
- **Kiểm tra lại quyền trong `onResume()`** để cập nhật trạng thái khi người dùng quay lại từ Cài đặt.
- **Lời giải thích** phải nói rõ app làm gì với quyền đó và điều gì sẽ không dùng được nếu từ chối.
- **`POST_NOTIFICATIONS`:**
  - chỉ xin khi `SDK_INT >= 33`;
  - tạo `NotificationChannel` một lần (API 26+);
  - bọc `notify()` trong `try-catch SecurityException`.
- **Ảnh:** `TakePicturePreview` chỉ trả ảnh thu nhỏ (khoảng 100–200 px). Ảnh đầy đủ phải dùng `TakePicture` + Uri từ `FileProvider` (lab sau). Chọn ảnh có sẵn thì dùng `PickVisualMedia`, **không cần quyền**: "quyền tốt nhất là quyền không phải xin".

**Áp dụng cho đề 5 (Đề xuất):**
- **Ảnh hiện trường lô:** ưu tiên `PickVisualMedia` (không cần quyền). Nếu chụp trực tiếp thì làm đủ mẫu ba nhánh cho `CAMERA`.
- **Upload ảnh lên Supabase Storage chưa có API.** Hiện backend chỉ nhận đường dẫn `anhUrl`/`anhHienTruongUrl`.
- **Thông báo** (ví dụ khi có phản ánh mới) là phần thêm, không bắt buộc.

## Lab A8: Giao diện modular với Fragment

**Quy ước lab:**
- **Một Activity chứa nhiều Fragment.** Fragment không khai báo trong Manifest; nhận dữ liệu qua `Bundle` arguments.
- **Khung chứa là `FragmentContainerView`**, không dùng `FrameLayout`. Mọi thay đổi gói trong `beginTransaction() … commit()`, và `commit()` chạy bất đồng bộ.
- **Chỉ nạp Fragment mặc định khi `savedInstanceState == null`**, nếu không xoay màn hình sẽ nạp chồng Fragment.
- **Vòng đời:**
  - `onCreateView` chỉ inflate;
  - `findViewById` và gán sự kiện trong `onViewCreated`;
  - không giữ tham chiếu View sau `onDestroyView`.
- **Back stack:**
  - chuyển tab dùng `replace` và **không** `addToBackStack` (Back ở tab thì thoát app);
  - mở chi tiết dùng `replace` + `addToBackStack`;
  - lùi bằng code dùng `getParentFragmentManager().popBackStack()`.
- **Truyền dữ liệu vào Fragment bằng mẫu `newInstance(...)` + `setArguments`**, đọc bằng `requireArguments()`. Không dùng constructor có tham số, vì khi tạo lại hệ thống gọi constructor rỗng.
- **Hai Fragment trao đổi qua Fragment Result API:**
  - bên nhận gọi `setFragmentResultListener(KEY, getViewLifecycleOwner(), ...)`;
  - bên gửi gọi `setFragmentResult` rồi `popBackStack()`;
  - không gọi thẳng phương thức của Fragment khác, không dùng biến `static`.
- **`BottomNavigationView`:**
  - listener `return true` để tab được tô sáng;
  - dùng `if–else`, không dùng `switch` với `R.id` (từ AGP 8 `R.id` không còn là hằng số).
- **Nâng cao:** giữ trạng thái tab bằng `ViewModel` dùng chung; Navigation Component; master–detail với `layout-sw600dp`.

**Áp dụng cho đề 5 (Đề xuất):**
- **Màn hình chính:** `MainActivity` + `BottomNavigationView`. Tab hiển thị theo `vaiTro` lấy từ phản hồi đăng nhập; ẩn tab bằng cách ẩn menu item.
- **Mở chi tiết:** từ danh sách mở `ChiTietLoFragment.newInstance(loId)` và các màn hình chi tiết khác theo cùng mẫu, kèm `addToBackStack`.
- **Cập nhật danh sách sau thao tác:** sau khi duyệt hoặc từ chối, Fragment chi tiết gửi kết quả qua Fragment Result API để danh sách tải lại.

## Lab A9: Adapter, ListView và mẫu ViewHolder

**Quy ước lab:**
- **Adapter** là cầu nối dữ liệu–giao diện. `BaseAdapter` có 4 phương thức: `getCount`, `getItem`, `getItemId`, `getView`.
- **Lớp dữ liệu tách riêng.** Tiền tệ lưu bằng `int` (số đồng), chỉ định dạng khi hiển thị (`45000 → "45.000 đ"`); không dùng `double` cho tiền.
- **Layout một dòng riêng** (`item_...xml`):
  - gốc là `LinearLayout`, không có `ScrollView`;
  - khối giữa dùng `0dp` + `layout_weight="1"`;
  - `minHeight` ≥ 48dp;
  - tên dài dùng `maxLines="1"` + `ellipsize="end"`.
- **`inflate(layout, parent, false)`.** Tham số thứ ba là `true` sẽ gây crash.
- **Mẫu ViewHolder:**
  - giữ tham chiếu View qua `setTag/getTag`;
  - gán dữ liệu ở **mọi** lần gọi, không chỉ trong nhánh `convertView == null`.
- **Sửa danh sách xong phải gọi `notifyDataSetChanged()`**, và dùng `setEmptyView` khi danh sách rỗng.
- **`onItemLongClick` phải `return true`.** Lab A11 thay việc giữ lâu để xóa bằng context menu + hộp thoại xác nhận.
- **Tên file trong `res/drawable`** chỉ dùng chữ thường, số và `_`.
- **Lab A10 chuyển sang RecyclerView:**
  - ViewHolder là bắt buộc;
  - có `LayoutManager`;
  - có `notifyItemInserted/Removed`.

**Áp dụng cho đề 5 (Đề xuất):**
- **Danh sách dùng RecyclerView**, vì C.1 yêu cầu RecyclerView chứ không phải ListView. Ý tưởng Adapter và ViewHolder giữ nguyên như A9.
- **Mỗi danh sách có layout dòng riêng**, ví dụ `item_lo.xml` gồm mã truy xuất, tên sản phẩm, ngày sản xuất, số lượng còn và số bước.
- **Tiền:** giá dùng `int`, vì backend giới hạn giá ≤ 1.000.000.000, nhỏ hơn giới hạn của `int`. Tổng doanh số trong báo cáo có thể vượt giới hạn `int`, nên dùng `long`.

## Quy ước chung rút ra từ các lab

- **Log:** dùng `Log.d(TAG, ...)` và lọc Logcat theo TAG khi kiểm thử; TAG chứa mã nhóm (C.1 #10). Không dùng `System.out.println` (A1).
- **Tài nguyên:** chuỗi, màu và kích thước đặt trong `strings.xml`, `colors.xml`, `dimens.xml`; không viết cứng trong layout hoặc code (A3, A6). Dùng `dp`/`sp`, không dùng `px`.
- **Quy cách mã nguồn:** tên có nghĩa, tách phương thức, luôn gọi `super` trong callback vòng đời, xử lý sự kiện bằng `if/else` theo `R.id` (A1, A4).
- **Git:** commit theo từng phần việc, thông điệp mô tả việc đã làm, không commit `build/`, `.gradle/`, `local.properties` (A2).
- **Phiên bản Android:** minSdk 24. API mới hơn phải kiểm tra `Build.VERSION.SDK_INT` hoặc dùng bản tương thích (`IntentCompat`, `TextUtils.join`).
- **Bảng kiểm thử theo kịch bản:** mỗi lab có bảng kiểm thử, gồm thao tác và kết quả đúng phải thấy, kèm ảnh Logcat hoặc ảnh màn hình. Nên viết kiểm thử của app Admin theo cùng dạng để đưa vào bảng ≥ 25 trường hợp của báo cáo.
- **Đối chiếu Flutter:** slide A6, A8, A9 có so sánh với Flutter để dùng cho app Client:

  | Android | Flutter |
  | --- | --- |
  | Layout XML, `FrameLayout` chồng lớp, `<Space>`, `layout-land` (A3) | Widget, `Stack` + `Positioned`, `Spacer`, `LayoutBuilder` (F2 dựng lại màn hình A3) |
  | `EditText` + `setError` | `TextFormField` + `validator` |
  | Spinner | `DropdownButtonFormField` |
  | CheckBox | `CheckboxListTile` |
  | MaterialSwitch | `SwitchListTile` |
  | Kiểm tra cả form bằng tay | `_formKey.currentState!.validate()` |
  | FragmentTransaction + back stack | `Navigator.push/pop` + route stack |
  | Danh sách A9, A10 | Lab F5 làm lại cùng đề bài |

## Kiểm thử app Admin rút từ lab (Đề xuất)

| # | Thao tác | Kết quả đúng phải thấy | Lab |
| --- | --- | --- | --- |
| 1 | Để trống từng ô của form tạo lô rồi bấm Lưu | Báo lỗi đúng ô, con trỏ nhảy vào ô đó, không gọi API | A6 |
| 2 | Nhập số lượng là chữ | Báo lỗi tại ô số lượng, app không crash | A6, A9 |
| 3 | Xoay màn hình khi đang nhập form tạo lô | Dữ liệu đã nhập còn nguyên | A2, A6 |
| 4 | Xoay màn hình ở màn hình chi tiết lô | Đúng lô (nhờ arguments), không nạp chồng Fragment | A8 |
| 5 | Mở chi tiết rồi bấm Back | Quay về danh sách, không thoát app; ở tab thì Back thoát app | A8 |
| 6 | Duyệt sản phẩm ở chi tiết rồi quay lại | Danh sách chờ duyệt cập nhật ngay | A8 |
| 7 | Đăng nhập `NHAN_VIEN` | Không thấy nút Duyệt/Từ chối và tab Báo cáo | A8, C.1 #2 |
| 8 | Tắt Wi-Fi rồi mở danh sách | Ẩn ProgressBar, báo "Không kết nối được máy chủ", không văng | Phụ lục 2 |
| 9 | Token hết hạn hoặc bị xóa rồi gọi API | Nhận 401, tự đăng xuất về màn hình đăng nhập | Phụ lục 2, C.1 #1 |
| 10 | Bấm gọi nhà cung cấp hoặc chia sẻ mã lô trên máy không có app phù hợp | Báo lỗi nhẹ nhàng, không crash | A5 |
| 11 | Từ chối quyền camera hai lần rồi bấm chụp (nếu có chụp ảnh) | Mời mở Cài đặt; bật quyền xong quay lại thì trạng thái tự cập nhật | A7 |
| 12 | Danh sách rỗng (ví dụ không còn hồ sơ chờ duyệt) | Hiện dòng "trống" thay vì màn hình trắng | A9 |
| 13 | Dán chữ vào ô số lượng, hoặc nhập số rất lớn | Báo lỗi tại ô, không crash | A4 |
| 14 | Bật "Không giữ hoạt động", nhập dở form rồi nhấn Home và quay lại | Dữ liệu đang nhập vẫn còn | A2 |
| 15 | Đặt cỡ chữ hệ thống lớn nhất, xoay ngang ở form | Chữ co giãn theo cài đặt, nội dung cuộn được, bàn phím không che nút | A3 |
| 16 | Nhấn Back ở tab đầu tiên (Android 12+) | App xuống nền; mở lại vẫn còn phiên đăng nhập | A1, A8 |
