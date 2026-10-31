# Gugugaga Android Project

Đồ án INT4211 đề 5: hệ thống sàn đặc sản vùng và sản phẩm OCOP. Hệ thống cần hai ứng dụng: Admin Android Java/XML và Client Flutter, cùng sử dụng backend và cơ sở dữ liệu chung.

Bắt đầu từ [danh mục tài liệu dự án](docs/README.md) để xem mục tiêu, chức năng, quy tắc, công nghệ và yêu cầu nộp bài. [AGENTS.md](AGENTS.md) ghi các quy tắc làm việc trong repository.

## Cấu trúc và tiến độ

| Thư mục | Nội dung | Trạng thái |
| --- | --- | --- |
| [`backend/`](backend/README.md) | REST API Node.js/Express, `schema.sql`, `seed.sql` | Đã có luồng truy xuất xuyên suốt (duyệt → lô → QR công khai), kiểm thử tự động trên PostgreSQL cục bộ. Chưa deploy; chưa có API đơn hàng, đánh giá, báo cáo. |
| `admin-android/` | App Admin Java/XML | Chưa bắt đầu. |
| `client-flutter/` | App Client Flutter | Chưa bắt đầu. |

Cách chạy backend, tài khoản thử nghiệm và các bước deploy: [backend/README.md](backend/README.md). Danh sách API: [docs/development/API.md](docs/development/API.md). Mã nhóm chưa được xác nhận, nên tên app, package và TAG log (`[OCOP-API]`) cần bổ sung mã nhóm khi biết.
