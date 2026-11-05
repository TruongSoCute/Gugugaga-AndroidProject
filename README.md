# Gugugaga Android Project

Đồ án INT4211 đề 5: hệ thống sàn đặc sản vùng và sản phẩm OCOP. Hệ thống cần hai ứng dụng: Admin Android Java/XML và Client Flutter, cùng sử dụng backend và cơ sở dữ liệu chung.

Bắt đầu từ [danh mục tài liệu dự án](docs/README.md) để xem mục tiêu, chức năng, quy tắc, công nghệ và yêu cầu nộp bài. [AGENTS.md](AGENTS.md) ghi các quy tắc làm việc trong repository.

**Thành viên mới:** đọc theo thứ tự [Setup](docs/development/Setup.md) (cài đặt và chạy), [Architecture](docs/development/Architecture.md) (hệ thống được tổ chức thế nào), [Contributing](docs/development/Contributing.md) (quy trình làm việc nhóm), rồi [việc tiếp theo](docs/development/Plan.md#trạng-thái-hiện-tại-và-việc-tiếp-theo).

## Hệ thống đang chạy

- **API:** https://ocop-backend.onrender.com — kiểm tra sức khỏe: https://ocop-backend.onrender.com/health
- **CSDL:** PostgreSQL trên Supabase (project `Gugugaga-Android`), backend kết nối qua Session pooler cổng 5432.
- Render gói Free ngủ sau 15 phút không có yêu cầu; lần gọi đầu mất tới một phút. Gọi thử `/health` 2–3 phút trước khi demo.
- **Phát hành:** `main` không deploy. Merge `main` vào nhánh `release` thì GitHub Actions chạy toàn bộ test, deploy backend và đăng APK hai app lên [Releases](https://github.com/TruongSoCute/Gugugaga-AndroidProject/releases). Xem [Setup mục 8](docs/development/Setup.md#8-phát-hành-tự-động-nhánh-release).

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
| [`backend/`](backend/README.md) | REST API Node.js/Express, `schema.sql`, `seed.sql`; TAG log `[GUGUGAGA-API]` | Đủ các nhóm API của đề: truy xuất QR công khai, giỏ/đơn hàng (gán lô FIFO), nhà cung cấp tự gửi hồ sơ, đánh giá, phản ánh, yêu thích, theo dõi, báo cáo doanh số, tải ảnh. 78 test đạt. Đã deploy bản trước trên Render; CSDL trên Supabase. |
| [`admin-android/`](admin-android/README.md) | App Admin Java/XML, package `vn.edu.vhu.ltdd.gugugaga.admin` | 13 màn hình gọi API thật: sản phẩm, nhà cung cấp, lô + QR, đơn hàng, phản ánh, báo cáo biểu đồ; đủ 10 yêu cầu C.1. 63 test, build được APK. Chưa chạy thử trên thiết bị. |
| [`client-flutter/`](client-flutter/README.md) | App Client Flutter, package `vn.edu.vhu.ltdd.gugugaga.ocop_client` | 22 màn hình cho khách (mua hàng, đánh giá kèm ảnh, phản ánh, quét QR) và nhà cung cấp (hồ sơ, sản phẩm chờ duyệt). 60 test, build được APK. Chưa chạy thử trên thiết bị. |

Cách chạy từng phần, tài khoản thử nghiệm và các bước deploy nằm trong README của từng thư mục. Danh sách API: [docs/development/API.md](docs/development/API.md).

## Đóng góp, bảo mật, giấy phép

- [Hướng dẫn đóng góp](.github/CONTRIBUTING.md) (bản đầy đủ: [docs/development/Contributing.md](docs/development/Contributing.md)); báo lỗi và đề xuất qua [Issues](https://github.com/TruongSoCute/Gugugaga-AndroidProject/issues/new/choose) theo mẫu.
- [Quy tắc ứng xử](CODE_OF_CONDUCT.md).
- [Chính sách bảo mật](SECURITY.md): báo lỗ hổng riêng tư, không mở issue công khai.
- Mã nguồn phát hành theo [giấy phép MIT](LICENSE). Đây là đồ án học phần; quy định học phần về sao chép mã giữa các nhóm vẫn áp dụng cho sinh viên cùng học phần.
- ## 🚀 Hướng dẫn Build APK (Optimized size)

Dự án sử dụng cơ chế chia nhỏ APK theo kiến trúc chip (`--split-per-abi`) để tối ưu hóa dung lượng ứng dụng cho người dùng cuối.

### Các bước thực hiện:

1. Di chuyển vào thư mục ứng dụng Flutter:
   ```bash
   cd client-flutter
