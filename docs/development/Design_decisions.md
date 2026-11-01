# Quyết định thiết kế đang áp dụng

Nguồn và cách phân biệt yêu cầu: xem [README](../README.md).

Tài liệu này ghi các phương án **Đề xuất** mà backend hiện đang áp dụng để có thể làm luồng xuyên suốt theo [Plan](Plan.md) bước 2. Các mục này **chưa được giảng viên hoặc cả nhóm xác nhận**. Nếu nhóm thay đổi, cần sửa cùng lúc `backend/db/schema.sql`, code và [API](API.md). Các câu hỏi còn mở vẫn nằm trong [Open questions](Open_questions.md).

## Vai trò và phân quyền (Đề xuất)

| Chức năng | `QUAN_TRI` | `NHAN_VIEN` | `KHACH` | `NHA_CUNG_CAP` | Không đăng nhập |
| --- | :---: | :---: | :---: | :---: | :---: |
| Xem sản phẩm/nhà cung cấp đã duyệt, truy xuất QR, xem đánh giá | ✓ | ✓ | ✓ | ✓ | ✓ |
| Nhập hồ sơ nhà cung cấp, chứng nhận, sản phẩm cho bất kỳ nhà cung cấp | ✓ | ✓ | | | |
| Gửi/sửa hồ sơ và sản phẩm **của chính mình** (chờ duyệt) | | | | ✓ | |
| Xem hồ sơ mọi trạng thái (app Admin) | ✓ | ✓ | | | |
| **Duyệt/từ chối** nhà cung cấp và sản phẩm, chốt hạng sao | ✓ | | | | |
| Tạo lô, thêm bước truy xuất | ✓ | ✓ | | | |
| Xử lý đơn (xác nhận, giao, hủy kèm lý do) | ✓ | ✓ | | | |
| Xử lý phản ánh | ✓ | ✓ | | | |
| Báo cáo doanh số | ✓ | | | | |
| Giỏ hàng, đặt đơn, hủy đơn chưa xác nhận, xác nhận đã nhận | | | ✓ | | |
| Đánh giá (đơn đã nhận), báo cáo vi phạm, yêu thích, theo dõi | | | ✓ | | |
| Tải ảnh lên | ✓ | ✓ | ✓ | ✓ | |

- Đăng ký công khai chỉ tạo `KHACH` hoặc `NHA_CUNG_CAP` (trường `loaiTaiKhoan`); không bao giờ tạo nhân sự. Tài khoản `QUAN_TRI`/`NHAN_VIEN` có sẵn trong `seed.sql`; chức năng tạo tài khoản nhân sự chưa làm.
- Backend đọc lại vai trò từ CSDL ở mỗi request, không tin vai trò ghi trong token; tài khoản bị khóa (`dang_hoat_dong = false`) bị từ chối ngay cả khi token còn hạn.
- Lý do tách quyền duyệt: người nhập liệu không tự duyệt hồ sơ của mình, đáp ứng yêu cầu hai vai trò Admin nhìn thấy chức năng khác nhau.

## Nhà cung cấp dùng app Client (Nhóm đã chốt)

Nhóm đã quyết định (01/11/2026): nhà cung cấp có tài khoản `NHA_CUNG_CAP` và dùng **app Client** để gửi hồ sơ và sản phẩm chờ duyệt. Đề không nói ai gửi hồ sơ, còn slide giới thiệu ghi app Client dành cho khách, nên vẫn nên báo giảng viên khi demo. Tạo lô, sinh QR và nhập bước truy xuất vẫn làm trên app Admin, vì đề ghi đây là chức năng của Admin.

- Mỗi tài khoản sở hữu **đúng một** hồ sơ (`nha_cung_cap.tai_khoan_id UNIQUE`). Hồ sơ nhân sự nhập hộ có `tai_khoan_id = NULL`; app Admin hiển thị cờ `tuGui` để phân biệt.
- Hồ sơ và sản phẩm mới luôn `CHO_DUYET`. Backend bỏ qua `trangThaiDuyet`, `hangSao`, `nhaCungCapId` do app gửi; sản phẩm luôn gắn với hồ sơ của tài khoản đang đăng nhập.
- Nhà cung cấp sửa được hồ sơ/sản phẩm khi đang `CHO_DUYET` hoặc `TU_CHOI`; sửa xong quay về `CHO_DUYET` để quản trị duyệt lại (sản phẩm bị xóa hạng sao). Hồ sơ/sản phẩm đã `DA_DUYET` không tự sửa được, vì đang bán công khai; cần liên hệ quản trị.
- Hồ sơ bị từ chối thì chưa thêm được sản phẩm mới (giống quy tắc khi nhân sự nhập).
- Nhà cung cấp chỉ thấy dữ liệu của mình: sản phẩm của hồ sơ khác trả `404`. Không dùng được API nhân sự, giỏ hàng hay đặt đơn.

## Đánh giá, phản ánh, yêu thích, báo cáo, ảnh (Đề xuất)

- **Đánh giá:** chỉ khách có đơn `DA_NHAN` chứa sản phẩm đó; mỗi sản phẩm trong một đơn đánh giá một lần (`UNIQUE (khach_id, san_pham_id, don_hang_id)`); 1–5 sao, tối đa 5 ảnh. Đánh giá công khai chỉ hiện tên người đánh giá.
- **Phản ánh:** khách gửi kèm mã lô (nếu có) để gắn với đúng lô; mã của sản phẩm khác bị từ chối. Trạng thái chỉ đi tới `MOI → DANG_XU_LY → DA_XU_LY | BAC_BO`; kết thúc phải ghi kết quả xử lý. Nhân sự thấy email người báo để liên hệ; khách chỉ thấy phản ánh của mình.
- **Yêu thích, theo dõi:** chỉ sản phẩm đang bán và nhà cung cấp đã duyệt; thêm/bỏ gọi lại không lỗi. Sản phẩm bị thu hồi duyệt tự ẩn khỏi danh sách yêu thích.
- **Báo cáo doanh số:** tính trên đơn `DA_GIAO`, `DA_NHAN`; doanh số = số lượng × đơn giá lúc đặt, không gồm phí giao; theo vùng của lô thực tế đã giao; lọc theo ngày đặt (giờ Việt Nam). Chỉ `QUAN_TRI` xem.
- **Ảnh:** app gửi byte ảnh lên backend (`POST /tai-len/anh`); backend kiểm tra byte đầu tệp (JPEG/PNG/WebP, ≤ 5 MB), đặt tên ngẫu nhiên và lưu lên Supabase Storage bucket công khai `ocop-anh` bằng khóa service role chỉ có trên Render. CSDL chỉ lưu URL, không lưu base64.

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

## Đơn hàng và gán lô (Đề xuất)

- Trạng thái đơn: `CHO_XAC_NHAN → DA_XAC_NHAN → DANG_GIAO → DA_GIAO → DA_NHAN`, hoặc `DA_HUY`. Lịch sử chuyển trạng thái lưu ở `lich_su_trang_thai_don`.
- Gán lô **lúc đặt đơn** theo FIFO (lô sản xuất trước bán trước) trong một transaction có khóa dòng `SELECT … FOR UPDATE`, trừ `so_luong_con` của lô. Nếu một lô không đủ, dòng hàng được chia sang nhiều lô; mỗi lô là một dòng `chi_tiet_don`. Khóa ngoại `(lo_id, san_pham_id)` bảo đảm lô thuộc đúng sản phẩm.
- Ai được chuyển trạng thái:
  - nhân sự: `CHO_XAC_NHAN → DA_XAC_NHAN → DANG_GIAO → DA_GIAO`; hủy được khi đơn chưa giao (`CHO_XAC_NHAN`, `DA_XAC_NHAN`) và phải ghi lý do;
  - khách: hủy đơn của mình khi còn `CHO_XAC_NHAN`; chỉ khách mới xác nhận `DA_NHAN`, khi đơn đã `DA_GIAO`.
  Không được nhảy cóc hay quay lui. Hủy đơn hoàn lại `so_luong_con` cho đúng các lô đã trừ, trong cùng transaction với việc đổi trạng thái.
- Chỉ bán lô còn hạn sử dụng (`han_su_dung` sau ngày hôm nay theo giờ Việt Nam). Khóa lô theo thứ tự `id` để các đơn đặt đồng thời không gây deadlock.
- Giá, phí giao và tổng tiền do backend tính; `chi_tiet_don.don_gia` lưu giá tại thời điểm đặt. Giỏ hàng chỉ lưu sản phẩm và số lượng, luôn hiển thị giá hiện hành.
- Phí giao cố định theo hình thức: `TIEU_CHUAN` 30.000 đ, `NHANH` 50.000 đ, `NHAN_TAI_CHO` 0 đ (khai báo ở `backend/src/domains/don-hang/config.js`). Không tích hợp hãng vận chuyển thật; "vận chuyển liên vùng" được quản lý bằng trạng thái đơn và vùng của lô. Cần giảng viên xác nhận (xem [Open questions](Open_questions.md)).
- Doanh số tính trên đơn `DA_GIAO` và `DA_NHAN`, theo vùng của **lô thực tế đã giao**.

## Bảo mật Supabase

- Mọi bảng bật Row Level Security nhưng không có policy. Như vậy REST API tự động của Supabase (dùng anon key) không đọc hoặc ghi được dữ liệu, kể cả `mat_khau_hash`. Backend kết nối bằng chủ sở hữu bảng qua `DATABASE_URL`, nên RLS không chặn backend.
- Hai app chỉ gọi backend Express, không nhúng khóa Supabase nào.
