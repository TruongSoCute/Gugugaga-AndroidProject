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

Quyền và quy tắc dưới đây theo [Design decisions](Design_decisions.md) (**Đề xuất**, chưa xác nhận). Đã triển khai đủ các nhóm API của đề: xác thực, danh mục, nhà cung cấp (kể cả nhà cung cấp tự gửi hồ sơ), sản phẩm, lô và truy xuất QR, giỏ hàng và đơn hàng, đánh giá, phản ánh, yêu thích, theo dõi, báo cáo doanh số, tải ảnh.

### Quy ước chung

- JSON dùng khóa camelCase; tiền là số nguyên VND; ngày `YYYY-MM-DD`; thời điểm ISO 8601 (gửi lên phải có múi giờ, ví dụ `2026-03-01T07:00:00+07:00`; trả về dạng UTC `…Z`).
- API cần đăng nhập nhận header `Authorization: Bearer <token>`.
- Ký hiệu quyền: **Công khai** (không cần token), **Đăng nhập** (mọi vai trò), **Khách** (chỉ `KHACH`), **Nhà cung cấp** (chỉ `NHA_CUNG_CAP`), **Nhân sự** (`QUAN_TRI`, `NHAN_VIEN`), **Quản trị** (chỉ `QUAN_TRI`).
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
| `POST /auth/dang-ky` | Công khai | Body `email`, `matKhau` (8–72 byte), `hoTen`, `soDienThoai?`, `loaiTaiKhoan?` (`KHACH` mặc định hoặc `NHA_CUNG_CAP`; giá trị khác bị 400). Không bao giờ tạo nhân sự; `vaiTro` client gửi bị bỏ qua. `201 { token, nguoiDung }`; `409 EMAIL_DA_TON_TAI`. |
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
| `GET /quan-tri/nha-cung-cap?trangThai=&vung=&trang=&kichThuoc=` | Nhân sự | Mọi trạng thái, hồ sơ chờ duyệt xếp trước. Có `trangThaiDuyet, lyDoTuChoi, tuGui` (`true` nếu nhà cung cấp tự gửi từ app Client). |
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

### Giỏ hàng và đơn hàng

Quy tắc theo [Design decisions](Design_decisions.md#đơn-hàng-và-gán-lô-đề-xuất) (**Đề xuất**).

| Phương thức, đường dẫn | Quyền | Mô tả |
| --- | --- | --- |
| `GET /don-hang/hinh-thuc-giao` | Công khai | `[{ ma, ten, phiGiao }]` cho `TIEU_CHUAN` (30.000 đ), `NHANH` (50.000 đ), `NHAN_TAI_CHO` (0 đ). |
| `GET /gio-hang` | Khách | `{ duLieu: [{ sanPhamId, ten, anhUrl, donViTinh, gia, soLuong, thanhTien, dangBan, conHang }], tamTinh }`. `gia` là giá hiện hành; `tamTinh` chỉ cộng sản phẩm còn bán; `conHang` là tổng tồn các lô còn hạn. |
| `PUT /gio-hang/:sanPhamId` | Khách | Body `{ soLuong }` (1–999): thêm mới hoặc đặt lại số lượng. Trả giỏ như trên. `404` nếu sản phẩm không đang bán. |
| `DELETE /gio-hang/:sanPhamId` | Khách | Xóa khỏi giỏ, trả giỏ. `404` nếu không có trong giỏ. |
| `POST /don-hang` | Khách | Body `hinhThucGiao, tenNguoiNhan, sdtNguoiNhan, diaChiGiao, ghiChu?, cacDong?: [{ sanPhamId, soLuong }]`. Không gửi `cacDong` thì đặt **toàn bộ giỏ** và xóa giỏ sau khi đặt. Giá, phí giao, tổng tiền và lô do backend quyết định; `gia`, `tongTien`, `trangThai`… client gửi bị bỏ qua. `201` trả chi tiết đơn. `400` giỏ trống/dữ liệu sai; `409 SAN_PHAM_KHONG_CON_BAN`; `409 KHONG_DU_HANG` (mỗi phần tử `chiTiet` có thêm `sanPhamId`, `conLai`). |
| `GET /don-hang?trangThai=&trang=&kichThuoc=` | Khách | Đơn của chính khách, mới nhất trước: `id, trangThai, hinhThucGiao, tongTien, taoLuc, capNhatLuc, khachId, tenKhach, tenNguoiNhan, soSanPham, tenSanPhamDau, anhSanPhamDau`. |
| `GET /don-hang/:id` | Đăng nhập | Khách chỉ xem đơn của mình (đơn người khác trả `404`); nhân sự xem mọi đơn. Trả thông tin đơn, `tenKhach, emailKhach`, `chiTiet[] (sanPhamId, tenSanPham, anhUrl, donViTinh, loId, maTruyXuat, ngaySanXuat, vungNguyenLieu, soLuong, donGia, thanhTien)` và `lichSu[] (trangThai, ghiChu, thoiDiem, nguoiThucHien)`. |
| `PATCH /don-hang/:id/trang-thai` | Đăng nhập | Body `{ trangThai, ghiChu? }`. Nhân sự: `CHO_XAC_NHAN → DA_XAC_NHAN → DANG_GIAO → DA_GIAO`, hủy (`DA_HUY`) khi chưa giao và **bắt buộc** `ghiChu`. Khách (đơn của mình): hủy khi còn `CHO_XAC_NHAN`, xác nhận `DA_NHAN` khi đơn `DA_GIAO`. `403` vai trò không bao giờ được chuyển tới trạng thái đó; `409 TRANG_THAI_KHONG_HOP_LE` sai thứ tự. Hủy đơn hoàn tồn cho đúng các lô đã trừ. |
| `GET /quan-tri/don-hang?trangThai=&khachId=&trang=&kichThuoc=` | Nhân sự | Mọi đơn, cùng dạng danh sách như trên. |
| `GET /quan-tri/don-hang/:id` | Nhân sự | Như `GET /don-hang/:id`. |

### Nhà cung cấp tự quản lý hồ sơ và sản phẩm (app Client)

Tài khoản `NHA_CUNG_CAP` gửi hồ sơ và sản phẩm chờ duyệt, chỉ thấy và sửa dữ liệu của mình, không tự đổi trạng thái duyệt hay hạng sao. Quản trị duyệt trên app Admin bằng các API duyệt ở trên. Quy tắc: [Design decisions](Design_decisions.md#nhà-cung-cấp-dùng-app-client-nhóm-đã-chốt).

| Phương thức, đường dẫn | Quyền | Mô tả |
| --- | --- | --- |
| `GET /cua-toi/nha-cung-cap` | Nhà cung cấp | Hồ sơ của tài khoản (như `GET /quan-tri/nha-cung-cap/:id`, có `trangThaiDuyet`, `lyDoTuChoi`, `chungNhan[]`). `404 CHUA_CO_HO_SO` nếu chưa gửi. |
| `POST /cua-toi/nha-cung-cap` | Nhà cung cấp | Body như `POST /nha-cung-cap`. Hồ sơ luôn `CHO_DUYET`, gắn với tài khoản. `201`; `409 DA_CO_HO_SO` (mỗi tài khoản một hồ sơ); `409 CHUNG_NHAN_TRUNG`. |
| `PUT /cua-toi/nha-cung-cap` | Nhà cung cấp | Sửa hồ sơ đang `CHO_DUYET` hoặc `TU_CHOI`: thay toàn bộ chứng nhận, đưa về `CHO_DUYET` (gửi duyệt lại). `409 HO_SO_DA_DUYET` nếu đã duyệt. |
| `GET /cua-toi/san-pham` | Nhà cung cấp | Sản phẩm của mình, mọi trạng thái: `id, ten, moTa, donViTinh, gia, hangSao, anhUrl, trangThaiDuyet, lyDoTuChoi, duyetLuc, taoLuc, soLo, tonKho`. Chưa có hồ sơ thì trả `[]`. |
| `GET /cua-toi/san-pham/:id` | Nhà cung cấp | Một sản phẩm của mình; sản phẩm của người khác trả `404`. |
| `POST /cua-toi/san-pham` | Nhà cung cấp | Body `ten, gia, moTa?, donViTinh?, anhUrl?`. `nhaCungCapId`, `hangSao`, `trangThaiDuyet` client gửi bị bỏ qua. `201` sản phẩm `CHO_DUYET`. `409 CHUA_CO_HO_SO`, `409 NHA_CUNG_CAP_BI_TU_CHOI`. |
| `PUT /cua-toi/san-pham/:id` | Nhà cung cấp | Body như trên. Chỉ sửa sản phẩm `CHO_DUYET`/`TU_CHOI`, sửa xong về `CHO_DUYET` và xóa hạng sao. `409 SAN_PHAM_DA_DUYET`. |

### Đánh giá

| Phương thức, đường dẫn | Quyền | Mô tả |
| --- | --- | --- |
| `GET /danh-gia?sanPhamId=&trang=&kichThuoc=` | Công khai | `{ duLieu: [{ id, sanPhamId, donHangId, soSao, noiDung, taoLuc, tenNguoiDanhGia, anh[] }], phanTrang, tongHop: { soDanhGia, diemTrungBinh } }`. Không có email hay số điện thoại người đánh giá. |
| `POST /danh-gia` | Khách | Body `donHangId, sanPhamId, soSao (1–5), noiDung?, anhUrls? (tối đa 5 URL, lấy từ API tải ảnh)`. Chỉ đơn của mình, đã `DA_NHAN`, có sản phẩm đó. Đánh giá và ảnh lưu trong một transaction. `201`; `404` đơn không phải của mình; `400` sản phẩm không có trong đơn; `409 DON_CHUA_NHAN`; `409 DA_DANH_GIA`. Chi tiết đơn (`GET /don-hang/:id`) có cờ `chiTiet[].daDanhGia`. |

### Phản ánh hàng giả, sai mô tả

| Phương thức, đường dẫn | Quyền | Mô tả |
| --- | --- | --- |
| `POST /bao-cao-vi-pham` | Khách | Body `sanPhamId, loai (HANG_GIA, SAI_MO_TA, KHAC), noiDung, maTruyXuat?, anhUrl?`. Có `maTruyXuat` thì gắn với đúng lô; mã của sản phẩm khác trả `400`. Luôn bắt đầu ở `MOI`. `201`. |
| `GET /bao-cao-vi-pham?trangThai=&loai=` | Khách | Phản ánh của chính mình. |
| `GET /bao-cao-vi-pham/:id` | Khách | Của người khác trả `404`. |
| `GET /quan-tri/bao-cao-vi-pham?trangThai=&loai=&trang=&kichThuoc=` | Nhân sự | Mọi phản ánh, `MOI` xếp trước: `id, sanPhamId, tenSanPham, anhSanPham, nhaCungCapId, tenNhaCungCap, loId, maTruyXuat, loai, noiDung, anhUrl, trangThai, ketQuaXuLy, xuLyLuc, taoLuc, nguoiBaoId, tenNguoiBao, tenNguoiXuLy`. |
| `GET /quan-tri/bao-cao-vi-pham/:id` | Nhân sự | Như trên, thêm `emailNguoiBao` để liên hệ. |
| `PATCH /quan-tri/bao-cao-vi-pham/:id` | Nhân sự | Body `{ trangThai: DANG_XU_LY \| DA_XU_LY \| BAC_BO, ketQuaXuLy? }`; `ketQuaXuLy` bắt buộc khi `DA_XU_LY`/`BAC_BO`. Chỉ đi tới: `MOI → DANG_XU_LY → DA_XU_LY/BAC_BO`. `409 TRANG_THAI_KHONG_HOP_LE`. |

### Yêu thích và theo dõi

| Phương thức, đường dẫn | Quyền | Mô tả |
| --- | --- | --- |
| `GET /yeu-thich` | Khách | Sản phẩm yêu thích còn đang bán: `id, ten, gia, donViTinh, hangSao, anhUrl, nhaCungCapId, tenNhaCungCap, taoLuc`. |
| `PUT /yeu-thich/:sanPhamId`, `DELETE /yeu-thich/:sanPhamId` | Khách | Thêm/bỏ, gọi lại không lỗi. Trả `{ sanPhamId, yeuThich }`. Sản phẩm không đang bán: `404`. |
| `GET /theo-doi` | Khách | Nhà cung cấp đang theo dõi: `id, ten, diaChi, anhCoSoUrl, tenVung, soSanPham, taoLuc`. |
| `PUT /theo-doi/:nhaCungCapId`, `DELETE /theo-doi/:nhaCungCapId` | Khách | Trả `{ nhaCungCapId, theoDoi }`. Nhà cung cấp chưa duyệt: `404`. `soNguoiTheoDoi` trong `GET /nha-cung-cap/:id` thay đổi tương ứng. |

### Báo cáo doanh số

`GET /bao-cao/doanh-so?tu=&den=&vung=` — **Quản trị**. `tu`, `den` là ngày đặt đơn (YYYY-MM-DD, giờ Việt Nam, tính cả hai đầu); `vung` là vùng của **lô thực tế đã giao**. Chỉ tính đơn `DA_GIAO`, `DA_NHAN`; doanh số = số lượng × đơn giá lúc đặt, không gồm phí giao.

```json
{
  "boLoc": { "tu": null, "den": null, "vung": null, "trangThaiTinh": ["DA_GIAO", "DA_NHAN"] },
  "tong": { "doanhSo": 41230000, "soLuong": 120, "soDon": 30 },
  "theoVung": [{ "vungId": 1, "tenVung": "Cần Giờ", "doanhSo": 0, "soLuong": 0 }],
  "theoHangSao": [{ "hangSao": 3, "doanhSo": 0, "soLuong": 0 }],
  "nhaCungCapBanChay": [{ "id": 3, "ten": "…", "tenVung": "…", "doanhSo": 0, "soLuong": 0, "soDon": 0 }]
}
```

`theoVung` luôn đủ mọi vùng (vùng chưa bán được có `doanhSo = 0`), `theoHangSao` luôn đủ 3, 4, 5 sao, `nhaCungCapBanChay` tối đa 5 dòng. `400` khi `tu > den` hoặc ngày sai định dạng.

### Tải ảnh

`POST /tai-len/anh?mucDich=` — **Đăng nhập**. Body là **byte của ảnh** (không phải JSON), header `Content-Type: image/jpeg | image/png | image/webp`, tối đa 5 MB. `mucDich`: `danh-gia`, `san-pham`, `nha-cung-cap`, `lo`, `phan-anh` (thư mục lưu). Backend kiểm tra byte đầu tệp để chắc là ảnh thật, đặt tên tệp ngẫu nhiên, lưu lên Supabase Storage (bucket công khai `ocop-anh`) và trả `201 { "url": "https://…/storage/v1/object/public/ocop-anh/…" }`. Dùng `url` này cho `anhUrls` của đánh giá, `anhUrl` của sản phẩm, `anhCoSoUrl`, `anhHienTruongUrl`.

`415 KHONG_PHAI_ANH`; `413` quá 5 MB; `503 CHUA_CAU_HINH_LUU_ANH` khi backend chưa có `SUPABASE_URL`/`SUPABASE_SERVICE_KEY` (app nên cho nhập URL ảnh thay thế); `502 LUU_ANH_THAT_BAI` khi Supabase lỗi.

## Kiểm thử tự động

`backend/test/` có 78 trường hợp (gồm 2 trường hợp kiểm tra kiến trúc phân tầng) chạy với CSDL PostgreSQL thật, xem [backend/README](../../backend/README.md). Các trường hợp bao gồm: `/health`; đăng nhập đúng/sai; thiếu token, token giả, token hết hạn; khách gọi API nhân sự bị 403; nhân viên duyệt bị 403; dữ liệu sai bị 400; rollback khi tạo nhà cung cấp lỗi; luồng duyệt → tạo hai lô cùng sản phẩm → quét từng mã không đăng nhập thấy đúng hành trình; mã không tồn tại trả 404; truy xuất không lộ dữ liệu nội bộ; ràng buộc mã trùng; seed đủ số lượng; giỏ hàng; đặt đơn tính tiền ở backend; gán lô FIFO và chia nhiều lô; thiếu hàng thì rollback; lô hết hạn không bán; hai khách đặt cùng lúc không bán vượt tồn; khách không xem được đơn người khác; chuyển trạng thái đơn theo vai trò; hủy đơn hoàn tồn; nhà cung cấp tự gửi hồ sơ và sản phẩm, chỉ thấy và sửa dữ liệu của mình, không tự duyệt; không tự đăng ký được nhân sự; đánh giá chỉ cho đơn đã nhận, không trùng; phản ánh gắn đúng lô, xử lý chỉ đi tới; yêu thích/theo dõi; báo cáo doanh số khớp số liệu tính trực tiếp từ CSDL, chỉ quản trị xem; tải ảnh chỉ nhận ảnh thật, báo 503 khi chưa cấu hình.
