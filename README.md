# Gugugaga Android Project

Đồ án INT4211 đề 5: hệ thống sàn đặc sản vùng và sản phẩm OCOP. Hệ thống cần hai ứng dụng: Admin Android Java/XML và Client Flutter, cùng sử dụng backend và cơ sở dữ liệu chung.

Bắt đầu từ [danh mục tài liệu dự án](docs/README.md) để xem mục tiêu, chức năng, quy tắc, công nghệ và yêu cầu nộp bài. [AGENTS.md](AGENTS.md) ghi các quy tắc làm việc trong repository.

## Cấu trúc và tiến độ

Mã nhóm: **gugugaga**. Tên app, package và TAG log đều chứa mã này.

| Thư mục | Nội dung | Trạng thái |
| --- | --- | --- |
| [`backend/`](backend/README.md) | REST API Node.js/Express, `schema.sql`, `seed.sql`; TAG log `[GUGUGAGA-API]` | Luồng truy xuất xuyên suốt: duyệt → lô → QR công khai. 45 test đạt trên PostgreSQL cục bộ. **Chưa deploy**; chưa có API đơn hàng, đánh giá, báo cáo. |
| [`admin-android/`](admin-android/README.md) | App Admin Java/XML, package `vn.edu.vhu.ltdd.gugugaga.admin` | 2 màn hình gọi API thật: đăng nhập; danh sách sản phẩm có duyệt/từ chối. Thêm tab Tài khoản. Build được APK, chưa chạy thử trên thiết bị. |
| [`client-flutter/`](client-flutter/README.md) | App Client Flutter, package `vn.edu.vhu.ltdd.gugugaga.ocop_client` | 2 màn hình gọi API thật: sản phẩm lọc theo vùng và hạng sao; truy xuất mã lô → hành trình. Build được APK, chưa chạy thử trên thiết bị. |

Cách chạy từng phần, tài khoản thử nghiệm và các bước deploy nằm trong README của từng thư mục. Danh sách API: [docs/development/API.md](docs/development/API.md).
