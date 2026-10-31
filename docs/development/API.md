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

## Đã triển khai trong `backend/`

Quyền và quy tắc dưới đây theo [Design decisions](Design_decisions.md) (**Đề xuất**, chưa xác nhận). Chưa triển khai: đơn hàng, giỏ, đánh giá, báo cáo vi phạm, yêu thích, theo dõi, báo cáo doanh số, upload ảnh.

### Quy ước chung

- JSON dùng khóa camelCase; tiền là số nguyên VND; ngày `YYYY-MM-DD`; thời điểm ISO 8601 (gửi lên phải có múi giờ, ví dụ `2026-03-01T07:00:00+07:00`; trả về dạng UTC `…Z`).
- API cần đăng nhập nhận header `Authorization: Bearer <token>`.
- Ký hiệu quyền: **Công khai** (không cần token), **Đăng nhập** (mọi vai trò), **Nhân sự** (`QUAN_TRI`, `NHAN_VIEN`), **Quản trị** (chỉ `QUAN_TRI`).
- Danh sách có phân trang nhận `trang` (mặc định 1) và `kichThuoc` (mặc định 20, tối đa 100), trả `{ "duLieu": [...], "phanTrang": { "trang", "kichThuoc", "tong" } }`.
- Lỗi luôn có dạng:

```json
{ "loi": { "ma": "DU_LIEU_KHONG_HOP_LE", "thongDiep": "Dữ liệu không hợp lệ.", "chiTiet": [{ "truong": "gia", "thongDiep": "Bắt buộc nhập." }] } }
```

| Mã HTTP | Khi nào |
| --- | --- |
| 400 | Thiếu/sai dữ liệu, JSON hỏng, tham số lọc sai, `:id` không phải số nguyên dương. |
| 401 | Thiếu token, token sai/hết hạn (`TOKEN_HET_HAN`), sai email hoặc mật khẩu, tài khoản bị khóa khi dùng token. |
| 403 | Đúng token nhưng vai trò không đủ quyền (`KHONG_DU_QUYEN`); đăng nhập bằng tài khoản bị khóa. |
| 404 | Không có bản ghi hoặc bản ghi chưa được công bố; đường dẫn không tồn tại. |
| 409 | Trùng dữ liệu (email, số hiệu chứng nhận, thứ tự bước), vi phạm quy tắc trạng thái (ví dụ duyệt sản phẩm khi nhà cung cấp chưa duyệt). |
| 500 | Lỗi máy chủ; không trả chi tiết nội bộ. |
| 503 | `/health` khi không kết nối được CSDL. |

### Hệ thống và xác thực

| Phương thức, đường dẫn | Quyền | Mô tả |
| --- | --- | --- |
| `GET /health` | Công khai | `200 { "trangThai": "ok", "csdl": "ok", "thoiGian" }`; `503` nếu mất kết nối CSDL. |
| `POST /auth/dang-ky` | Công khai | Body `email`, `matKhau` (8–72 byte), `hoTen`, `soDienThoai?`. Luôn tạo `KHACH`. `201 { token, nguoiDung }`; `409 EMAIL_DA_TON_TAI`. |
| `POST /auth/dang-nhap` | Công khai | Body `email`, `matKhau`. `200 { token, nguoiDung: { id, email, hoTen, soDienThoai, vaiTro } }`; `401` khi sai email **hoặc** mật khẩu (cùng thông điệp); `403` khi tài khoản bị khóa. |
| `GET /auth/toi` | Đăng nhập | Thông tin tài khoản hiện tại. App dùng để kiểm tra token còn hạn khi mở lại. |

Token hết hạn sau `JWT_EXPIRES_IN` (mặc định 8 giờ). Khi nhận 401, app xóa token và đưa về màn hình đăng nhập.

### Danh mục công khai (app Client)

| Phương thức, đường dẫn | Quyền | Mô tả |
| --- | --- | --- |
| `GET /vung-nguyen-lieu` | Công khai | Danh sách vùng: `id, ten, moTa, viDo, kinhDo`. |
| `GET /san-pham?vung=&hangSao=&tuKhoa=&nhaCungCapId=&trang=&kichThuoc=` | Công khai | Chỉ sản phẩm đã duyệt của nhà cung cấp đã duyệt. `vung` là id vùng của nhà cung cấp; `hangSao` 3–5. Mỗi phần tử: `id, ten, moTa, donViTinh, gia, hangSao, anhUrl, nhaCungCapId, tenNhaCungCap, vungId, tenVung, soDanhGia, diemTrungBinh`. |
| `GET /san-pham/:id` | Công khai | Như trên, thêm `diaChiNhaCungCap, anhCoSoUrl, chungNhan[] (loai, soHieu, ngayCap, ngayHetHan, anhUrl, conHieuLuc), danhGiaGanDay[] (soSao, noiDung, taoLuc, tenNguoiDanhGia, anh[])`. `404` nếu chưa công bố. |
| `GET /nha-cung-cap?vung=` | Công khai | Nhà cung cấp đã duyệt, kèm `soNguoiTheoDoi`. |
| `GET /nha-cung-cap/:id` | Công khai | Chi tiết nhà cung cấp đã duyệt, kèm `chungNhan[]` và `sanPham[]` đã duyệt. |

### Truy xuất QR

`GET /truy-xuat/:maTruyXuat`. **Công khai, không cần JWT.** Mã gồm 20 ký tự hex và không phân biệt hoa thường. Trả `404` khi mã không tồn tại, sai định dạng hoặc lô thuộc sản phẩm/nhà cung cấp không còn được duyệt.

```json
{
  "maTruyXuat": "B056FB25CA6642785532",
  "lo": {
    "ngaySanXuat": "2026-03-02", "hanSuDung": "2027-03-02",
    "nguoiSanXuat": "Tổ sản xuất B (mẫu)", "anhHienTruongUrl": "https://…",
    "vungNguyenLieu": { "id": 1, "ten": "Cần Giờ", "moTa": "…", "viDo": 10.4114, "kinhDo": 106.9539 }
  },
  "sanPham": { "id": 1, "ten": "Khô cá dứa 500 g", "moTa": "…", "donViTinh": "gói", "hangSao": 4, "anhUrl": "https://…" },
  "nhaCungCap": {
    "id": 1, "ten": "HTX Hải sản khô Cần Giờ (mẫu)", "diaChi": "…", "anhCoSoUrl": "https://…", "vung": "Cần Giờ",
    "chungNhan": [{ "loai": "OCOP", "soHieu": "MAU-OCOP-001", "ngayCap": "2024-03-11", "ngayHetHan": "2027-03-11", "anhUrl": "https://…", "conHieuLuc": true }]
  },
  "cacBuoc": [
    { "thuTu": 1, "tenBuoc": "Thu hoạch", "moTa": "…", "thoiDiem": "2026-02-27T00:00:00.000Z", "anhUrl": "https://…" }
  ]
}
```

### Quản trị nhà cung cấp và sản phẩm (app Admin)

| Phương thức, đường dẫn | Quyền | Mô tả |
| --- | --- | --- |
| `GET /quan-tri/nha-cung-cap?trangThai=&vung=&trang=&kichThuoc=` | Nhân sự | Mọi trạng thái, hồ sơ chờ duyệt xếp trước. Có `trangThaiDuyet, lyDoTuChoi`. |
| `GET /quan-tri/nha-cung-cap/:id` | Nhân sự | Chi tiết hồ sơ kèm `chungNhan[]`, `nguoiDuyet`, `duyetLuc`. |
| `POST /nha-cung-cap` | Nhân sự | Body `ten, nguoiDaiDien, soDienThoai, diaChi, vungId, anhCoSoUrl?, chungNhan?: [{ loai, soHieu, ngayCap, ngayHetHan?, anhUrl? }]`. Lưu hồ sơ và chứng nhận trong **một transaction**. `201` hồ sơ `CHO_DUYET`; `409 CHUNG_NHAN_TRUNG`. |
| `PATCH /nha-cung-cap/:id/duyet` | Quản trị | Body `{ "trangThai": "DA_DUYET" \| "TU_CHOI", "lyDo"? }`; `lyDo` bắt buộc khi từ chối. `409`: `TRANG_THAI_KHONG_DOI`, `THIEU_ANH_CO_SO`, `THIEU_CHUNG_NHAN_OCOP`. |
| `GET /quan-tri/san-pham?trangThai=&vung=&hangSao=&tuKhoa=&nhaCungCapId=` | Nhân sự | Mọi trạng thái, thêm `trangThaiDuyet, trangThaiNhaCungCap`. |
| `GET /quan-tri/san-pham/:id` | Nhân sự | Chi tiết, thêm `lyDoTuChoi, duyetLuc`. |
| `POST /san-pham` | Nhân sự | Body `nhaCungCapId, ten, gia, moTa?, donViTinh?, anhUrl?`. `201` sản phẩm `CHO_DUYET`, `hangSao = null`; `409 NHA_CUNG_CAP_BI_TU_CHOI`. |
| `PATCH /san-pham/:id/duyet` | Quản trị | Body `{ "trangThai": "DA_DUYET", "hangSao": 3–5 }` hoặc `{ "trangThai": "TU_CHOI", "lyDo": "…" }`. `409 NHA_CUNG_CAP_CHUA_DUYET`, `TRANG_THAI_KHONG_DOI`. |

### Lô sản xuất và bước truy xuất (app Admin)

| Phương thức, đường dẫn | Quyền | Mô tả |
| --- | --- | --- |
| `GET /lo-san-xuat?sanPhamId=&trang=&kichThuoc=` | Nhân sự | Danh sách lô: `id, maTruyXuat, sanPhamId, tenSanPham, ngaySanXuat, hanSuDung, soLuong, soLuongCon, tenVung, nguoiSanXuat, soBuoc`. |
| `GET /lo-san-xuat/:id` | Nhân sự | Chi tiết lô, thêm `duongDanTruyXuat` (nội dung để vẽ QR) và `cacBuoc[]`. |
| `POST /lo-san-xuat` | Nhân sự | Body `sanPhamId, ngaySanXuat, hanSuDung (> ngaySanXuat), soLuong, nguoiSanXuat, vungNguyenLieuId? (mặc định vùng nhà cung cấp), anhHienTruongUrl?, ghiChu?, cacBuoc?: [{ thuTu?, tenBuoc, moTa?, thoiDiem, anhUrl? }]`. Mã truy xuất do server sinh. Lô và các bước được lưu trong **một transaction**. `201` trả chi tiết lô; `409 SAN_PHAM_BI_TU_CHOI`. |
| `POST /lo-san-xuat/:id/buoc` | Nhân sự | Body `tenBuoc, thoiDiem, thuTu?, moTa?, anhUrl?`; không gửi `thuTu` thì lấy thứ tự kế tiếp. `201`; `404` lô không tồn tại; `409 THU_TU_BUOC_TRUNG`. |

## Kiểm thử tự động

`backend/test/` có 43 trường hợp chạy với CSDL PostgreSQL thật, xem [backend/README](../../backend/README.md). Các trường hợp bao gồm: `/health`; đăng nhập đúng/sai; thiếu token, token giả, token hết hạn; khách gọi API nhân sự bị 403; nhân viên duyệt bị 403; dữ liệu sai bị 400; rollback khi tạo nhà cung cấp lỗi; luồng duyệt → tạo hai lô cùng sản phẩm → quét từng mã không đăng nhập thấy đúng hành trình; mã không tồn tại trả 404; truy xuất không lộ dữ liệu nội bộ; ràng buộc mã trùng; seed đủ số lượng.
