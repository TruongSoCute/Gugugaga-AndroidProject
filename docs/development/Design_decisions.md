# Quyết định thiết kế đang áp dụng

Nguồn và cách phân biệt yêu cầu: xem [README](../README.md).

Tài liệu này ghi các phương án **Đề xuất** mà backend hiện đang áp dụng để có thể làm luồng xuyên suốt theo [Plan](Plan.md) bước 2. Các mục này **chưa được giảng viên hoặc cả nhóm xác nhận**. Nếu nhóm thay đổi, cần sửa cùng lúc `backend/db/schema.sql`, code và [API](API.md). Các câu hỏi còn mở vẫn nằm trong [Open questions](Open_questions.md).

## Vai trò và phân quyền (Đề xuất)

| Chức năng | `QUAN_TRI` | `NHAN_VIEN` | `KHACH` | Không đăng nhập |
| --- | :---: | :---: | :---: | :---: |
| Xem sản phẩm/nhà cung cấp đã duyệt, truy xuất QR | ✓ | ✓ | ✓ | ✓ |
| Nhập hồ sơ nhà cung cấp, chứng nhận, sản phẩm | ✓ | ✓ | | |
| Xem hồ sơ mọi trạng thái (app Admin) | ✓ | ✓ | | |
| **Duyệt/từ chối** nhà cung cấp và sản phẩm, chốt hạng sao | ✓ | | | |
| Tạo lô, thêm bước truy xuất | ✓ | ✓ | | |
| Xử lý đơn và phản ánh *(chưa triển khai)* | ✓ | ✓ | | |
| Báo cáo doanh số *(chưa triển khai)* | ✓ | | | |
| Đặt đơn, đánh giá, báo cáo vi phạm, yêu thích *(chưa triển khai)* | | | ✓ | |

- Đăng ký công khai luôn tạo `KHACH`. Tài khoản `QUAN_TRI`/`NHAN_VIEN` hiện có sẵn trong `seed.sql`; chức năng tạo tài khoản nhân sự chưa làm.
- Backend đọc lại vai trò từ CSDL ở mỗi request, không tin vai trò ghi trong token; tài khoản bị khóa (`dang_hoat_dong = false`) bị từ chối ngay cả khi token còn hạn.
- Lý do tách quyền duyệt: người nhập liệu không tự duyệt hồ sơ của mình, đáp ứng yêu cầu hai vai trò Admin nhìn thấy chức năng khác nhau.

## Duyệt nhà cung cấp và sản phẩm (Đề xuất)

- Trạng thái: `CHO_DUYET`, `DA_DUYET`, `TU_CHOI`. Hồ sơ mới luôn `CHO_DUYET`; client gửi trạng thái hay hạng sao khi tạo sẽ bị bỏ qua.
- Từ chối bắt buộc có lý do (ràng buộc cả ở CSDL). Quản trị có thể duyệt lại hồ sơ bị từ chối hoặc thu hồi hồ sơ đã duyệt (chuyển sang `TU_CHOI` kèm lý do).
- Duyệt nhà cung cấp yêu cầu có ảnh cơ sở sản xuất và ít nhất một chứng nhận loại `OCOP` còn hiệu lực theo ngày Việt Nam.
- Duyệt sản phẩm yêu cầu nhà cung cấp đã duyệt và quản trị chọn hạng OCOP 3, 4 hoặc 5 sao.
- Sản phẩm chỉ được công bố khi **cả sản phẩm và nhà cung cấp** đang `DA_DUYET`.

## Lô và mã truy xuất (Đề xuất)

- Mã truy xuất do backend sinh từ 10 byte ngẫu nhiên an toàn mật mã (`crypto.randomBytes`), biểu diễn thành 20 ký tự hex in hoa. 80 bit ngẫu nhiên khiến việc đoán hoặc dò lần lượt là không khả thi; mã không lộ id hay thứ tự lô. CSDL có `UNIQUE` và `CHECK` định dạng.
- Nội dung in trên QR là đường dẫn `PUBLIC_BASE_URL/truy-xuat/<mã>`. App Client lấy đoạn cuối làm mã rồi gọi API; mở bằng camera điện thoại cũng xem được JSON (trang HTML là phần mở rộng).
- Vùng nguyên liệu được lưu theo **từng lô**, mặc định là vùng của nhà cung cấp, vì hai lô của cùng sản phẩm có thể lấy nguyên liệu từ vùng khác nhau.
- Không tạo lô cho sản phẩm bị từ chối. Lô được tạo khi sản phẩm còn chờ duyệt, nhưng chỉ công bố sau khi duyệt.
- `GET /truy-xuat/:ma` trả 404 khi mã không tồn tại **hoặc** sản phẩm/nhà cung cấp không còn ở trạng thái đã duyệt. App nên hiển thị "không xác minh được nguồn gốc", vì đây là tín hiệu cảnh báo cho người mua.
- Dữ liệu công khai của truy xuất chỉ gồm thông tin lô, sản phẩm, nhà cung cấp (tên, địa chỉ cơ sở, ảnh, chứng nhận) và các bước. Không trả id nội bộ của lô, tồn kho, ghi chú nội bộ, người nhập liệu, số điện thoại hay người đại diện.

## Đơn hàng và gán lô (Đề xuất, schema đã chuẩn bị, API chưa làm)

- Trạng thái đơn: `CHO_XAC_NHAN → DA_XAC_NHAN → DANG_GIAO → DA_GIAO → DA_NHAN`, hoặc `DA_HUY`. Lịch sử chuyển trạng thái lưu ở `lich_su_trang_thai_don`.
- Gán lô **lúc đặt đơn** theo FIFO (lô sản xuất trước bán trước) trong một transaction có khóa dòng `SELECT … FOR UPDATE`, trừ `so_luong_con` của lô. Nếu một lô không đủ, dòng hàng được chia sang nhiều lô; mỗi lô là một dòng `chi_tiet_don`. Khóa ngoại `(lo_id, san_pham_id)` bảo đảm lô thuộc đúng sản phẩm.
- Giá, phí giao và tổng tiền do backend tính; `chi_tiet_don.don_gia` lưu giá tại thời điểm đặt.
- Doanh số tính trên đơn `DA_GIAO` và `DA_NHAN`, theo vùng của **lô thực tế đã giao**.

## Bảo mật Supabase

- Mọi bảng bật Row Level Security nhưng không có policy. Như vậy REST API tự động của Supabase (dùng anon key) không đọc hoặc ghi được dữ liệu, kể cả `mat_khau_hash`. Backend kết nối bằng chủ sở hữu bảng qua `DATABASE_URL`, nên RLS không chặn backend.
- Hai app chỉ gọi backend Express, không nhúng khóa Supabase nào.
