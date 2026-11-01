# Gugugaga Android Project

Đồ án INT4211 đề 5: hệ thống sàn đặc sản vùng và sản phẩm OCOP. Hệ thống cần hai ứng dụng: Admin Android Java/XML và Client Flutter, cùng sử dụng backend và cơ sở dữ liệu chung.

Bắt đầu từ [danh mục tài liệu dự án](docs/README.md) để xem mục tiêu, chức năng, quy tắc, công nghệ và yêu cầu nộp bài. [AGENTS.md](AGENTS.md) ghi các quy tắc làm việc trong repository.

**Thành viên mới:** đọc theo thứ tự [Setup](docs/development/Setup.md) (cài đặt và chạy), [Architecture](docs/development/Architecture.md) (hệ thống được tổ chức thế nào), [Contributing](docs/development/Contributing.md) (quy trình làm việc nhóm), rồi [việc tiếp theo](docs/development/Plan.md#trạng-thái-hiện-tại-và-việc-tiếp-theo).

## Hệ thống đang chạy

- **API:** https://ocop-backend.onrender.com — kiểm tra sức khỏe: https://ocop-backend.onrender.com/health
- **CSDL:** PostgreSQL trên Supabase (project `Gugugaga-Android`), backend kết nối qua Session pooler cổng 5432.
- Render gói Free ngủ sau 15 phút không có yêu cầu; lần gọi đầu mất tới một phút. Gọi thử `/health` 2–3 phút trước khi demo.

Tài khoản thử nghiệm (mật khẩu chung `Demo@12345`):

| Vai trò | Email | Dùng ở |
| --- | --- | --- |
| Quản trị (`QUAN_TRI`) | `quantri@ocop.example` | App Admin |
| Nhân viên (`NHAN_VIEN`) | `nhanvien@ocop.example` | App Admin |
| Khách (`KHACH`) | `khach1@ocop.example` … `khach5@ocop.example` | App Client |
| Nhà cung cấp (`NHA_CUNG_CAP`) | `ncc1@ocop.example` (hồ sơ đã duyệt), `ncc11@ocop.example` (hồ sơ chờ duyệt) | App Client |

## Cấu trúc và tiến độ

Mã nhóm: **gugugaga**. Tên app, package và TAG log đều chứa mã này.

| Thư mục | Nội dung | Trạng thái |
| --- | --- | --- |
| [`backend/`](backend/README.md) | REST API Node.js/Express, `schema.sql`, `seed.sql`; TAG log `[GUGUGAGA-API]` | Luồng truy xuất xuyên suốt: duyệt → lô → QR công khai; giỏ hàng và đơn hàng (gán lô FIFO, chuyển trạng thái). 59 test đạt trên PostgreSQL cục bộ. Đã deploy: API trên Render, CSDL trên Supabase (đủ dữ liệu mẫu, RLS bật cho 16 bảng); chưa có API đánh giá, phản ánh, báo cáo doanh số. |
| [`admin-android/`](admin-android/README.md) | App Admin Java/XML, package `vn.edu.vhu.ltdd.gugugaga.admin` | 2 màn hình gọi API thật: đăng nhập; danh sách sản phẩm có duyệt/từ chối. Thêm tab Tài khoản. Build được APK, chưa chạy thử trên thiết bị. |
| [`client-flutter/`](client-flutter/README.md) | App Client Flutter, package `vn.edu.vhu.ltdd.gugugaga.ocop_client` | 2 màn hình gọi API thật: sản phẩm lọc theo vùng và hạng sao; truy xuất mã lô → hành trình. Build được APK, chưa chạy thử trên thiết bị. |

Cách chạy từng phần, tài khoản thử nghiệm và các bước deploy nằm trong README của từng thư mục. Danh sách API: [docs/development/API.md](docs/development/API.md).
