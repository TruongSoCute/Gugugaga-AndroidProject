# Backend: OCOP API (đề 05)

REST API Node.js/Express dùng chung cho app Admin Android và app Client Flutter. Dữ liệu nằm trên PostgreSQL (Supabase). Danh sách API, quyền và mã lỗi: [docs/development/API.md](../docs/development/API.md). Các quy tắc đang áp dụng (**Đề xuất**, chưa xác nhận): [Design decisions](../docs/development/Design_decisions.md).

**Trạng thái:** đã có `/health`, đăng ký/đăng nhập JWT, danh mục công khai, quản trị và duyệt nhà cung cấp/sản phẩm, quản lý lô và bước truy xuất, API truy xuất QR công khai, giỏ hàng và đơn hàng (gán lô FIFO, trừ/hoàn tồn trong transaction, chuyển trạng thái theo vai trò). Nhà cung cấp tự gửi hồ sơ và sản phẩm (`/cua-toi/...`), đánh giá kèm ảnh, phản ánh hàng giả/sai mô tả, yêu thích, theo dõi, báo cáo doanh số, tải ảnh lên Supabase Storage. **Đã deploy:** https://ocop-backend.onrender.com (Render, Frankfurt), CSDL trên Supabase (project `Gugugaga-Android`, eu-west-1).

## Cấu trúc

Backend chia theo **miền nghiệp vụ**. Mỗi miền gồm các tầng chỉ phụ thuộc theo một chiều; các mối quan tâm xuyên suốt đi vào qua **Providers**. Quy tắc này được kiểm tra bằng máy. Chi tiết và lý do: [Architecture](../docs/development/Architecture.md).

```
backend/
  db/schema.sql, db/seed.sql   Bảng (16 bảng, khóa ngoại, UNIQUE, CHECK, RLS) và dữ liệu mẫu giả lập
  src/
    server.js, app.js, config.js   App Wiring: đọc cấu hình, tạo Providers, ghép các miền, gắn đường dẫn
    providers/   db (pg, transaction), auth (JWT, vai trò), password (bcrypt), random (crypto), logger, http (lỗi)
    utils/       errors, validator, sql (camel, phân trang...), http (bọc hàm async)
    domains/
      he-thong/      /health
      tai-khoan/     /auth
      danh-muc/      /vung-nguyen-lieu
      nha-cung-cap/  /nha-cung-cap, /quan-tri/nha-cung-cap
      san-pham/      /san-pham, /quan-tri/san-pham
      truy-xuat/     /lo-san-xuat, /truy-xuat/:ma
      don-hang/      /gio-hang, /don-hang, /quan-tri/don-hang (config.js: phí giao)
      danh-gia/      /danh-gia
      phan-anh/      /bao-cao-vi-pham, /quan-tri/bao-cao-vi-pham
      tuong-tac/     /yeu-thich, /theo-doi
      bao-cao/       /bao-cao/doanh-so
      tai-len/       /tai-len/anh (qua providers/storage -> Supabase Storage)
        types.js     kiểm tra dữ liệu vào, hằng trạng thái (hàm thuần)
        repo.js      chỉ chứa SQL tham số hóa
        service.js   quy tắc nghiệp vụ, transaction
        routes.js    đọc request -> types -> service -> JSON
        index.js     tạo service + router cho app.js
  scripts/db-reset.js           Chạy schema.sql + seed.sql lên DATABASE_URL
  scripts/check-architecture.js Kiểm tra quy tắc phụ thuộc giữa các tầng
  test/                         Kiểm thử tự động (node:test)
```

Khi thêm miền mới (ví dụ `don-hang`): tạo `domains/don-hang/{types,repo,service,routes,index}.js`, rồi ghép trong `app.js`. Nếu cần dữ liệu của miền khác, truyền service đó vào ở `app.js`; không `require` thẳng thư mục miền khác.

## Chạy trên máy cá nhân

Cần Node.js 20 trở lên và PostgreSQL (cài cục bộ hoặc dùng một project Supabase riêng để phát triển).

```bash
cd backend
```

```bash
npm install
```

```bash
cp .env.example .env
```

Sửa `.env`: đặt `DATABASE_URL`, `DATABASE_SSL=false` nếu dùng PostgreSQL cục bộ, và `JWT_SECRET` tạo bằng:

```bash
node -e "console.log(require('crypto').randomBytes(48).toString('base64url'))"
```

Tạo bảng và dữ liệu mẫu (**xóa toàn bộ dữ liệu hiện có trong CSDL đó**):

```bash
npm run db:reset -- --yes
```

```bash
npm run dev
```

Mở `http://localhost:3000/health`, kết quả mong đợi là `{"trangThai":"ok","csdl":"ok",...}`. Từ máy ảo Android, gọi `http://10.0.2.2:3000`.

## Kiểm thử tự động

Bộ kiểm thử dùng một CSDL **riêng**. Mỗi file test xóa và tạo lại CSDL này từ `schema.sql` + `seed.sql`. Không trỏ `TEST_DATABASE_URL` vào CSDL thật.

```bash
TEST_DATABASE_URL=postgresql://user:pass@localhost:5432/ocop_test npm test
```

`npm test` gồm cả kiểm tra kiến trúc. Có thể chạy riêng phần này (không cần CSDL) bằng `npm run check:arch`.

Kết quả lần chạy gần nhất: 78/78 đạt trên PostgreSQL 16, Node.js 22.

## Tài khoản thử nghiệm (từ seed.sql)

Mật khẩu chung `Demo@12345`. Đây là tài khoản demo theo yêu cầu nộp bài; sau buổi demo nên đổi mật khẩu hoặc khóa các tài khoản này.

| Email | Vai trò |
| --- | --- |
| `quantri@ocop.example` | `QUAN_TRI` |
| `nhanvien@ocop.example` | `NHAN_VIEN` |
| `khach1@ocop.example` … `khach5@ocop.example` | `KHACH` |
| `ncc1@ocop.example` (sở hữu nhà cung cấp 1, đã duyệt), `ncc11@ocop.example` (nhà cung cấp 11, chờ duyệt) | `NHA_CUNG_CAP` |

Mã truy xuất của 100 lô mẫu được sinh ngẫu nhiên mỗi lần chạy seed. Có thể xem mã bằng `GET /lo-san-xuat` với token nhân sự, hoặc bằng `SELECT ma_truy_xuat FROM lo_san_xuat` trong Supabase SQL Editor.

Toàn bộ dữ liệu mẫu là giả lập: tên cơ sở có hậu tố "(mẫu)", số hiệu chứng nhận có tiền tố `MAU-` và ảnh là ảnh minh họa từ picsum.photos. Không trình bày dữ liệu này như thông tin đã được xác minh.

## Triển khai (cần thành viên có tài khoản thực hiện)

1. **Supabase:** tạo project, mở SQL Editor và chạy `db/schema.sql`, rồi `db/seed.sql`. Bạn cũng có thể đặt `DATABASE_URL` trỏ tới Supabase rồi chạy `npm run db:reset -- --yes`. Lấy chuỗi kết nối tại *Connect → Session pooler* (cổng 5432) theo hướng dẫn của tài liệu môn học.
2. **Render:** tạo Web Service từ repo, đặt *Root Directory* là `backend`, build bằng `npm ci`, start bằng `npm start`, health check `/health`. Bạn cũng có thể dùng Blueprint với file [render.yaml](../render.yaml). Khai báo biến môi trường `DATABASE_URL`, `DATABASE_SSL=true`, `JWT_SECRET` và `PUBLIC_BASE_URL=https://<tên-service>.onrender.com`. Khi dùng Blueprint, Render tự sinh `JWT_SECRET` và đặt service ở Frankfurt (gần Supabase eu-west-1).
3. Mở `https://<tên-service>.onrender.com/health` từ một máy khác và kiểm tra nhận được mã 200.

**Kết quả kiểm tra trên bản đã deploy (01/11/2026):** gọi từ một máy khác tới https://ocop-backend.onrender.com, 20/20 trường hợp đạt:
- `/health` trả 200 với `csdl: ok`;
- danh mục và lọc sản phẩm công khai;
- đăng nhập đúng cả 3 vai trò; đăng nhập sai mật khẩu bị 401;
- không token và token giả bị 401; khách gọi API quản trị và nhân viên duyệt sản phẩm bị 403;
- 100 lô mẫu; quét mã truy xuất không cần đăng nhập thấy đúng lô với 4 bước, không lộ dữ liệu nội bộ; mã không tồn tại bị 404;
- khách xem được giỏ và đơn của mình.

Lỗi đã gặp khi deploy: Blueprint tạo trước khi `render.yaml` có `generateValue`, nên service thiếu `JWT_SECRET` và backend dừng ngay lúc khởi động (log: `Thiếu biến môi trường JWT_SECRET`). Cách xử lý: thêm `JWT_SECRET` trong mục Environment rồi deploy lại.

**Bật tải ảnh:** trên Render khai báo `SUPABASE_URL=https://zskmoffykgvdpackenre.supabase.co` và `SUPABASE_SERVICE_KEY` (Supabase → Project Settings → API Keys → khóa *secret*, hoặc `service_role` kiểu cũ). Bucket công khai `ocop-anh` đã được tạo. Chưa khai báo thì `POST /tai-len/anh` trả 503 và app cho nhập URL ảnh thay thế.

Không commit `.env`. Khóa `SUPABASE_SERVICE_KEY` chỉ khai báo trên Render, không đưa vào app di động. Mọi bảng đã bật RLS không kèm policy, nên anon key của Supabase không đọc được dữ liệu qua REST API tự động.

## Giải thích nhanh để trình bày

- **SQL tham số hóa:** mọi câu SQL nằm trong các file `repo.js`. Giá trị người dùng gửi lên đều được truyền qua `$1, $2…` và không ghép vào chuỗi SQL, nhờ đó tránh SQL injection. Các test có thử từ khóa `' OR 1=1 --`.
- **Transaction:** khi tạo nhà cung cấp kèm chứng nhận, tạo lô kèm các bước, hoặc đặt đơn (lưu đơn, chi tiết, trừ tồn lô, ghi lịch sử, xóa giỏ), mọi lệnh nằm giữa `BEGIN` và `COMMIT`. Nếu một lệnh lỗi, `ROLLBACK` hoàn tác tất cả (xem `withTransaction` trong `src/providers/db.js`, được gọi ở tầng service).
- **Phân tầng:** muốn biết SQL ở đâu thì xem `repo.js`; quy tắc nghiệp vụ ở `service.js`; quyền ở `providers/auth.js` và chỗ gắn `auth.nhanSu`/`auth.quanTri` trong `routes.js`.
- **bcrypt:** CSDL chỉ lưu hash của mật khẩu. Khi đăng nhập, backend so sánh hash và không bao giờ trả hash về app.
- **JWT:** token ký bằng `JWT_SECRET` và có hạn dùng. Mỗi request, middleware kiểm tra chữ ký và hạn của token, rồi đọc lại vai trò trong CSDL, nên sửa vai trò trong token cũng không có tác dụng.
- **Không bán vượt tồn:** khi đặt đơn, backend khóa các lô của sản phẩm bằng `SELECT … FOR UPDATE`. Hai khách đặt cùng lúc phần hàng cuối thì người sau phải chờ người trước xong, rồi đọc lại tồn mới, nên chỉ một đơn thành công. Test `don-hang.test.js` gửi hai đơn song song để chứng minh; gỡ `FOR UPDATE` thì test này đỏ.
- **Gán lô FIFO:** mỗi dòng đơn được chia cho lô sản xuất sớm nhất còn hàng và còn hạn; không đủ thì lấy tiếp lô kế tiếp. Mỗi lô là một dòng `chi_tiet_don`, nên đơn hàng biết chính xác lô nào đã giao và khách tra được mã truy xuất của hàng mình mua.
- **Mã truy xuất khó đoán:** mã có 80 bit ngẫu nhiên từ `crypto.randomBytes`, không phải số tăng dần, nên không ai dò được mã của lô khác.
