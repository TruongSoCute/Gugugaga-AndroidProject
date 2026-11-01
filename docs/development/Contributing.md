# Quy trình làm việc nhóm

Tài liệu cho thành viên tham gia phát triển: cách chia việc, dùng Git, thêm chức năng và kiểm tra trước khi push. Cài đặt môi trường: [Setup](Setup.md). Tổ chức code: [Architecture](Architecture.md).

## 1. Đọc gì trước khi bắt đầu

| Thứ tự | Tài liệu | Để biết |
| --- | --- | --- |
| 1 | [Goal](Goal.md), [Product](Product.md) | Đề bài, chức năng bắt buộc của hai app |
| 2 | [Rule](Rule.md), [Design decisions](Design_decisions.md) | Quy tắc nghiệp vụ; phương án nhóm đang áp dụng (chưa xác nhận) |
| 3 | [Architecture](Architecture.md) | Hệ thống gồm những gì, code nằm ở đâu, quy tắc tầng được máy kiểm tra |
| 4 | [Setup](Setup.md) | Cài đặt, chạy, kiểm thử |
| 5 | [API](API.md), [Data model](Data_model.md) | Các endpoint đang có; bảng và quan hệ |
| 6 | [Plan](Plan.md#trạng-thái-hiện-tại-và-việc-tiếp-theo) | Đã làm gì, còn thiếu gì, nên nhận việc nào |
| Làm app Admin | [Labs Android](Labs_Android.md) | Kỹ thuật giảng viên dạy trong lab, phải dùng đúng |

Phân biệt **Bắt buộc** (từ đề, không được bỏ) và **Đề xuất** (nhóm tự chọn, có thể đổi khi cả nhóm hoặc giảng viên quyết định). Khi yêu cầu chưa rõ, ghi vào [Open questions](Open_questions.md), không tự coi giả định là yêu cầu chính thức.

## 2. Quy định của môn học ảnh hưởng tới cách làm

- **Mỗi người commit bằng tài khoản GitHub của mình**, ít nhất 15 commit có ý nghĩa, rải đều trong 8 tuần. Commit dồn vào hai ngày cuối sẽ bị hạ hệ số đóng góp. Commit do công cụ AI tạo với tên tác giả khác không được tính cho bạn.
- **Phải hiểu và giải thích được code mình nộp**, kể cả code có AI hỗ trợ. Khi bảo vệ, giảng viên hỏi theo lịch sử commit.
- **Mã nhóm `gugugaga`** phải có trong tên app, package (`vn.edu.vhu.ltdd.gugugaga…`) và TAG log (`GUGUGAGA_ADMIN`, `GUGUGAGA_CLIENT`, `[GUGUGAGA-API]`).
- **Không đổi stack bắt buộc** khi chưa được giảng viên cho phép, gồm Java/XML, Flutter, Node 20 + Express 4 + `pg`, Supabase và Render.
- **Code tham khảo trên mạng phải ghi nguồn** trong comment. Sao chép từ nhóm khác bị 0 điểm.

## 3. Chia việc theo miền

Mỗi người nhận trọn một **miền nghiệp vụ**, từ backend tới màn hình của app, để ít xung đột khi merge và commit thể hiện rõ phần việc của từng người. Ví dụ:

| Miền | Backend (`backend/src/domains/`) | App Admin (`ui/…`) | App Client (`screens/`) |
| --- | --- | --- | --- |
| Đơn hàng | `don-hang` | Danh sách đơn, chi tiết và xử lý trạng thái | Giỏ hàng, đặt đơn, theo dõi đơn |
| Đánh giá và phản ánh | `danh-gia` (chưa có) | Xử lý phản ánh | Đánh giá kèm ảnh, báo hàng giả |
| Báo cáo | `bao-cao` (chưa có) | Màn hình biểu đồ doanh số | — |
| Lô và truy xuất | `truy-xuat` | Danh sách lô, tạo lô, thêm bước, hiển thị QR | Quét QR bằng camera |
| Nhà cung cấp | `nha-cung-cap` | Duyệt hồ sơ nhà cung cấp | Trang nhà cung cấp, theo dõi |

Ghi tên người nhận việc vào bảng phân công của nhóm trước khi bắt đầu, để tránh hai người làm trùng.

## 4. Git: nhánh, commit, merge

1. Cập nhật `main` mới nhất:

   ```powershell
   git checkout main
   ```

   ```powershell
   git pull origin main
   ```
2. Tạo nhánh theo việc, đặt tên `<loai>/<mo-ta-ngan>`, ví dụ `feat/admin-don-hang`, `fix/client-timeout`, `docs/bao-cao-api`:

   ```powershell
   git checkout -b feat/admin-don-hang
   ```
3. Commit nhỏ, mỗi commit là một bước có ý nghĩa. Thông điệp ghi rõ đã làm gì, ví dụ:
   - `Them man hinh danh sach don hang cho app Admin (RecyclerView, loc trang thai)`
   - `Backend: API bao cao doanh so theo vung, kem test sai quyen`

   Tránh các thông điệp như `update`, `fix`, `abc`.
4. Chạy kiểm tra ở [mục 6](#6-kiểm-tra-trước-khi-push) rồi push:

   ```powershell
   git push -u origin feat/admin-don-hang
   ```
5. Mở Pull Request vào `main` trên GitHub. Mô tả đã làm gì, cách kiểm tra, và ảnh chụp màn hình nếu có giao diện. Nhờ ít nhất một thành viên khác xem, rồi mới merge.
6. **Merge vào `main` là Render tự deploy backend.** Chỉ merge khi test backend đã xanh.

Không commit trực tiếp lên `main`, trừ sửa tài liệu nhỏ đã được cả nhóm đồng ý.

## 5. Thêm một chức năng xuyên suốt

Ví dụ: "khách đánh giá sản phẩm đã mua". Làm theo thứ tự dưới đây, và có thể commit sau mỗi bước.

### 5.1. Chốt yêu cầu

- Đối chiếu [Product](Product.md) và [Rule](Rule.md). Điểm nào đề chưa quy định thì ghi **Đề xuất** vào [Design decisions](Design_decisions.md), ví dụ "chỉ đánh giá sản phẩm trong đơn đã `DA_NHAN`".
- Xem bảng liên quan trong [Data model](Data_model.md) và `backend/db/schema.sql`. Nhiều bảng đã có sẵn, ví dụ `danh_gia`, `anh_danh_gia`, `bao_cao_vi_pham`, `yeu_thich`, `theo_doi_nha_cung_cap`.

### 5.2. Backend

Theo [Architecture](Architecture.md#cách-thêm-hoặc-sửa-chức-năng-backend). Có thể lấy miền `don-hang` làm mẫu đầy đủ.

1. Tạo `backend/src/domains/<miền>/` với các file `types.js` → `repo.js` → `service.js` → `routes.js` → `index.js`.
2. Ghép trong `backend/src/app.js`. Nếu cần service của miền khác, truyền vào qua tham số, không `require` chéo.
3. Viết test trong `backend/test/<miền>.test.js` cho đủ bốn loại: thành công, sai quyền (401/403), dữ liệu sai (400), không tìm thấy hoặc xung đột (404/409).
4. Nếu đổi schema: sửa `db/schema.sql` (và `db/seed.sql` nếu cần dữ liệu mẫu), đồng thời làm theo [Setup mục 7](Setup.md#7-triển-khai-chủ-tài-khoản-rendersupabase) để cập nhật CSDL dùng chung.
5. Cập nhật [API](API.md): phương thức, quyền, body, phản hồi và mã lỗi.

### 5.3. App Admin (Java/XML)

1. `model/`: lớp dữ liệu khớp JSON, tiền dùng `int`/`long`.
2. `data/ApiService.java`: khai báo endpoint. Thêm `data/<Ten>Repository.java` bọc `ApiService` và gọi qua `GoiApi` để có đủ các nhánh thành công / lỗi / hết phiên.
3. `ui/<man-hinh>/`: Fragment + ViewModel (giữ danh sách khi xoay) + Adapter RecyclerView. Thể hiện đủ trạng thái đang tải / thành công / lỗi + nút *Thử lại* bằng `ui/chung/TrangThai`.
4. Chuỗi hiển thị đặt trong `res/values/strings.xml`, không viết cứng trong layout.
5. Dùng đúng kỹ thuật trong [Labs Android](Labs_Android.md).

### 5.4. App Client (Flutter)

1. `lib/models/`: lớp đọc JSON (`fromJson`).
2. `lib/data/<ten>_repository.dart`: gọi API qua `ApiClient` dùng chung.
3. `lib/screens/`: màn hình gọi repository, không gọi `http` trực tiếp. Sau mỗi `await`, kiểm tra `mounted` trước khi dùng `context`.
4. Widget dùng lại đặt ở `lib/widgets/`.

### 5.5. Hoàn tất

- Cập nhật README của thư mục liên quan (bảng tiến độ màn hình) và [Plan](Plan.md#trạng-thái-hiện-tại-và-việc-tiếp-theo).
- Chạy toàn bộ kiểm tra ở mục 6.

## 6. Kiểm tra trước khi push

| Đã sửa | Lệnh (chạy trong thư mục tương ứng) | Phải đạt |
| --- | --- | --- |
| `backend/` | `npm run check:arch` rồi `npm test` | Không vi phạm kiến trúc; mọi test đạt |
| `admin-android/` | `.\gradlew.bat testDebugUnitTest lintDebug` | ArchUnit xanh, lint 0 lỗi |
| `client-flutter/` | `flutter analyze` rồi `flutter test` | Không lỗi analyze; mọi test đạt |

**Khi kiểm tra kiến trúc báo đỏ: sửa code cho đúng tầng.** Không nới quy tắc, không sửa `scripts/check-architecture.js`, `KienTrucTest.java`, `kien_truc_test.dart`, và không thêm ngoại lệ để vượt qua. Muốn đổi quy tắc thì cả nhóm phải thống nhất trước, rồi cập nhật cùng lúc [Architecture](Architecture.md) và file kiểm tra.

## 7. Bảo mật: những điều không được làm

- Không commit `.env`, `keystore.properties`, `key.properties`, file `.jks`, mật khẩu, token hay chuỗi kết nối CSDL. `.gitignore` đã chặn các file này; kiểm tra `git status` trước khi commit.
- Nếu lỡ commit bí mật, **xóa file chưa đủ**, vì bí mật vẫn nằm trong lịch sử Git. Phải đổi ngay mật khẩu hoặc khóa đó (Supabase, `JWT_SECRET` trên Render), rồi báo nhóm.
- Không đưa khóa Supabase nào vào app di động. Hai app chỉ gọi backend Express.
- Backend phải tự kiểm tra quyền, giá, trạng thái và dữ liệu hợp lệ. Không tin dữ liệu app gửi lên, và không dựa vào việc ẩn nút trên app.
- SQL luôn dùng tham số `$1, $2…`, không ghép chuỗi. Nhiều thay đổi phải thành công cùng nhau thì dùng `db.withTransaction`.
- Không gửi mật khẩu hay khóa qua chat, kể cả chat với công cụ AI.

## 8. Làm việc với trợ lý AI

`AGENTS.md` ở thư mục gốc chứa quy tắc mà các công cụ AI (Claude Code, Codex…) tự đọc khi làm việc trong repo. Khi nhờ AI viết code:

- Yêu cầu AI đọc [Architecture](Architecture.md) trước, và chạy các lệnh kiểm tra ở mục 6.
- Đọc kỹ và chạy thử những gì AI viết. Bạn phải giải thích được code khi bảo vệ.
- Commit bằng tài khoản của bạn, sau khi đã hiểu thay đổi.
