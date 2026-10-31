# Kiến thức lab áp dụng cho app Admin Android

Nguồn và cách phân biệt yêu cầu: xem [README](../README.md).

Mục C.1 của đề ghi mỗi yêu cầu của app Admin lấy kiến thức từ lab nào, và app Admin được chấm 2,0 điểm theo đủ 10 yêu cầu đó. Vì vậy app Admin nên dùng đúng kỹ thuật và quy ước giảng viên đã dạy trong lab, không dùng cách khác khi lab đã có cách làm.

Tài liệu này tổng hợp từ:
- slide **Lab A5–A9** (Intent, control lựa chọn, quyền, Fragment, Adapter);
- **mục C.1** và **Phụ lục 2** (gọi API bằng Retrofit) của tài liệu đồ án.

Các mục ghi **Quy ước lab** là cách làm giảng viên dạy và chấm trong lab. Các mục ghi **Áp dụng cho đề 5 (Đề xuất)** là cách nhóm dự định dùng, chưa phải yêu cầu chính thức.

## Đối chiếu yêu cầu C.1 với lab

Lab A1–A4, A10–A15 và F1–F8 chưa có slide trong repo. Các dòng ghi "chưa có slide" cần bổ sung khi có tài liệu.

| # | Yêu cầu C.1 (bắt buộc) | Lab theo đề | Nguồn đang có | Áp dụng cho đề 5 (Đề xuất) |
| --- | --- | --- | --- | --- |
| 1 | Đăng nhập, lưu token, tự đăng xuất khi token hết hạn | A5, A7 | A5 (chuyển màn hình). Slide A7 dạy quyền truy cập, không nói về token. Cách lưu token lấy theo **Phụ lục 2**: `SharedPreferences` + interceptor | `LoginActivity` gọi `POST /auth/dang-nhap`, lưu `token` và `vaiTro`; nhận 401 thì xóa token và về màn hình đăng nhập |
| 2 | Ít nhất 2 vai trò thấy chức năng khác nhau | A8 | A8 | `QUAN_TRI` thấy thêm nút Duyệt/Từ chối và tab Báo cáo; `NHAN_VIEN` nhập liệu, quản lý lô, đơn và phản ánh (theo [Design decisions](Design_decisions.md)). Backend vẫn chặn bằng 403 |
| 3 | ≥ 2 danh sách RecyclerView + Adapter + ViewHolder | A9, A10 | A9 (Adapter, ViewHolder với ListView). A10 (RecyclerView) chưa có slide | Danh sách hồ sơ chờ duyệt, sản phẩm, lô, đơn hàng, phản ánh. **Phải dùng RecyclerView**, không dùng ListView |
| 4 | Nhiều màn hình bằng Fragment hoặc nhiều Activity | A5, A8 | A5, A8 | Một `MainActivity` + Fragment cho từng tab; màn hình chi tiết mở bằng Fragment có back stack |
| 5 | Form kiểm tra hợp lệ, báo lỗi đúng chỗ | A4, A6 | A6 (A4 chưa có slide) | Form tạo lô, thêm bước truy xuất, nhập nhà cung cấp/sản phẩm, lý do từ chối |
| 6 | Hộp thoại xác nhận trước khi xóa; Toast/Snackbar báo kết quả | A11 | Chưa có slide (A7 có ví dụ `AlertDialog.Builder`) | Xác nhận trước khi từ chối hồ sơ, hủy đơn, xóa |
| 7 | ≥ 1 màn hình báo cáo có biểu đồ (MPAndroidChart hoặc tự vẽ) | A9–A12 | Chưa có slide về biểu đồ | Doanh số theo vùng, theo hạng sao, nhà cung cấp bán tốt nhất |
| 8 | Đủ 3 trạng thái khi gọi API: đang tải / thành công / lỗi mạng | A7, A14 | **Phụ lục 2 mục 2.4** (A14 chưa có slide) | Mọi màn hình gọi API có `ProgressBar`, danh sách rỗng và thông báo lỗi |
| 9 | Không mất dữ liệu form khi xoay màn hình | A2 | Chưa có slide; A5, A6, A8 có nhắc lại (xem từng lab bên dưới) | Form tạo lô và form từ chối giữ dữ liệu khi xoay |
| 10 | Tên app và TAG log chứa mã nhóm | A1 | Chưa có slide | Tên app, package và `TAG` theo mã nhóm khi biết |

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

- **Log:** dùng `Log.d(TAG, ...)` và lọc Logcat theo TAG khi kiểm thử; TAG chứa mã nhóm (C.1 #10).
- **Chuỗi:** chuỗi hiển thị đặt trong `strings.xml`, không nối chuỗi rải rác trong code.
- **Phiên bản Android:** minSdk 24. API mới hơn phải kiểm tra `Build.VERSION.SDK_INT` hoặc dùng bản tương thích (`IntentCompat`, `TextUtils.join`).
- **Bảng kiểm thử theo kịch bản:** mỗi lab có bảng kiểm thử, gồm thao tác và kết quả đúng phải thấy, kèm ảnh Logcat hoặc ảnh màn hình. Nên viết kiểm thử của app Admin theo cùng dạng để đưa vào bảng ≥ 25 trường hợp của báo cáo.
- **Đối chiếu Flutter:** slide A6, A8, A9 có so sánh với Flutter để dùng cho app Client:

  | Android | Flutter |
  | --- | --- |
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
