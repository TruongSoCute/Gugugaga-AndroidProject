# API định hướng

Nguồn và cách phân biệt yêu cầu: xem [README](../README.md).

| API | Mục đích |
| --- | --- |
| `GET /san-pham?vung=&hangSao=&tuKhoa=` | Lọc và tìm sản phẩm. |
| `GET /truy-xuat/:maTruyXuat` | Công khai, trả hành trình của đúng lô. |
| `POST /nha-cung-cap`, `PATCH /nha-cung-cap/:id/duyet` | Tạo và duyệt hồ sơ. |
| `POST /lo-san-xuat`, `POST /lo-san-xuat/:id/buoc` | Tạo lô và bước truy xuất. |
| `POST /don-hang`, `PATCH /don-hang/:id/trang-thai` | Đặt đơn và xử lý trạng thái. |
| `POST /danh-gia`, `POST /bao-cao-vi-pham` | Đánh giá và phản ánh. |
| `GET /bao-cao/doanh-so?vung=&tu=&den=` | Báo cáo doanh số. |

Đây là nhóm API chính trong đề, chưa đầy đủ: cần bổ sung xác thực, danh sách/chi tiết, QR, giỏ, yêu thích, theo dõi, upload và các thao tác quản trị theo thiết kế. Lập `api.md` hoặc Postman collection, ghi phương thức, quyền, tham số, phản hồi và mã lỗi 200, 201, 400, 401, 403, 404, 409, 500 khi phù hợp.
