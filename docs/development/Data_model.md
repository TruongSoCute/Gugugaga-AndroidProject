# Mô hình dữ liệu định hướng

Nguồn và cách phân biệt yêu cầu: xem [README](../README.md).

**Bắt buộc:** tối thiểu 8 bảng có khóa ngoại thật và ràng buộc hợp lý, `schema.sql` và `seed.sql` chạy lại được trên CSDL trống. Đề gợi ý các bảng sau; nhóm cần bổ sung bảng để đáp ứng toàn bộ chức năng.

| Nhóm | Bảng gợi ý | Quan hệ và ý nghĩa |
| --- | --- | --- |
| Danh mục | `vung_nguyen_lieu`, `nha_cung_cap`, `chung_nhan`, `san_pham` | Nhà cung cấp thuộc vùng, có chứng nhận và sản phẩm; sản phẩm có hạng sao, trạng thái duyệt. |
| Truy xuất | `lo_san_xuat`, `buoc_truy_xuat` | Một sản phẩm có nhiều lô, một lô có nhiều bước; mã truy xuất duy nhất. Lưu vùng, người sản xuất và ảnh phù hợp yêu cầu của lô. |
| Mua hàng | `nguoi_dung`, `don_hang`, `chi_tiet_don` | Đơn thuộc khách; chi tiết liên kết sản phẩm và lô thực tế đã giao. Cần thiết kế thêm nếu một dòng giao nhiều lô. |
| Tương tác | `danh_gia`, `bao_cao_vi_pham`, `yeu_thich`, `theo_doi_nha_cung_cap` | Lưu đánh giá, ảnh, báo cáo và quan hệ giữa người dùng với sản phẩm hoặc nhà cung cấp. |

Khóa ngoại liên kết các bản ghi hợp lệ; `UNIQUE` ngăn trùng mã lô; `NOT NULL` bảo đảm trường bắt buộc. Không dùng tên bảng trong danh sách này như một thiết kế hoàn chỉnh: nhóm cần vẽ ERD, chốt thuộc tính, quyền và vòng đời dữ liệu trước khi viết schema.

## Các cột chính được đề gợi ý

Đây là thông tin tham khảo từ bảng của đề 5, chưa phải schema cuối cùng. Nhóm cần xác định khóa, kiểu dữ liệu và trường bắt buộc phù hợp khi thiết kế.

| Bảng | Các cột chính được gợi ý |
| --- | --- |
| `vung_nguyen_lieu` | ID, tên, mô tả, vĩ độ, kinh độ. |
| `nha_cung_cap` | ID, tên, người đại diện, số điện thoại, địa chỉ, ID vùng, trạng thái duyệt, ảnh cơ sở. |
| `chung_nhan` | ID, ID nhà cung cấp, loại, số hiệu, ngày cấp, ngày hết hạn, URL ảnh. |
| `san_pham` | ID, ID nhà cung cấp, tên, mô tả, giá, hạng sao, URL ảnh, trạng thái duyệt. |
| `lo_san_xuat` | ID, ID sản phẩm, mã truy xuất, ngày sản xuất, hạn sử dụng, số lượng, ghi chú. |
| `buoc_truy_xuat` | ID, ID lô, thứ tự, tên bước, mô tả, thời điểm, URL ảnh. |
| `don_hang`, `chi_tiet_don` | Đơn có ID, ID khách, tổng tiền, trạng thái, địa chỉ giao; chi tiết ghi ID lô đã giao. |
| `bao_cao_vi_pham` | ID, ID sản phẩm, ID lô, ID người báo, nội dung, URL ảnh, trạng thái. |

Thông tin vùng nguyên liệu, người sản xuất và ảnh hiện trường của lô cũng phải được hệ thống quản lý theo yêu cầu chức năng, dù bảng lô gợi ý trong đề chưa liệt kê hết các trường này.

## Schema đang triển khai

`backend/db/schema.sql` hiện có 16 bảng: `vung_nguyen_lieu`, `nguoi_dung`, `nha_cung_cap`, `chung_nhan`, `san_pham`, `lo_san_xuat`, `buoc_truy_xuat`, `gio_hang`, `don_hang`, `chi_tiet_don`, `lich_su_trang_thai_don`, `danh_gia`, `anh_danh_gia`, `bao_cao_vi_pham`, `yeu_thich`, `theo_doi_nha_cung_cap`. Ngoài các cột đề gợi ý, lô có thêm `so_luong_con`, `vung_nguyen_lieu_id`, `nguoi_san_xuat` và `anh_hien_truong_url`. `chi_tiet_don` và `bao_cao_vi_pham` tham chiếu `(lo_id, san_pham_id)` để bảo đảm lô thuộc đúng sản phẩm. Lý do và các quy tắc đề xuất: [Design decisions](Design_decisions.md).

**Khác biệt giữa schema đang chạy và sơ đồ ERD đề xuất bên dưới (cần nhóm chốt một phương án):**

| Điểm | Schema đang chạy (`backend/db/schema.sql`) | Sơ đồ ERD đề xuất |
| --- | --- | --- |
| Vai trò | `QUAN_TRI`, `NHAN_VIEN`, `KHACH`; nhân viên nhập hồ sơ nhà cung cấp (`nguoi_tao_id`) | Thêm `NHA_CUNG_CAP` có tài khoản riêng (`nha_cung_cap.nguoi_dung_id` `UNIQUE`), tự gửi hồ sơ qua app Client |
| Hạng sao | Chỉ `hang_sao` do Quản trị chốt khi duyệt | Thêm `hang_sao_de_nghi` do nhà cung cấp gửi |
| Mã truy xuất | 20 ký tự hex (80 bit ngẫu nhiên), `CHECK` định dạng | Ví dụ 16 ký tự từ `crypto.randomBytes` |
| Lô của dòng đơn | `chi_tiet_don.lo_id` `NOT NULL`, gán lô lúc đặt (FIFO) | `lo_id` có thể `NULL`, gán khi chuẩn bị giao |
| Giỏ hàng | Có bảng `gio_hang` | Lưu trên máy bằng `shared_preferences` |
| Số bảng | 16 | 17 |

Khi nhóm chọn phương án, cập nhật cùng lúc `schema.sql`, `seed.sql`, code backend, [API](API.md), [Design decisions](Design_decisions.md) và sơ đồ này.

## Sơ đồ ERD (đề xuất của nhóm)

**Đề xuất, chưa phải schema cuối cùng.** Sơ đồ dựa trên bảng gợi ý của đề 5, bổ sung các bảng cần cho chức năng bắt buộc (tài khoản, nhiều ảnh, đánh giá kèm ảnh, yêu thích, theo dõi). Sơ đồ cũng theo phương án nhóm đang đề xuất: nhà cung cấp có tài khoản riêng, đăng nhập app Client để gửi hồ sơ và sản phẩm chờ duyệt. Phương án này cần giảng viên xác nhận, xem [Open questions](Open_questions.md). Sơ đồ use case nằm ở [Use case](Use_case.md).

Cách đọc ký hiệu (crow's foot):

| Ký hiệu | Ý nghĩa |
| --- | --- |
| `PK` / `FK` / `UK` | Khóa chính / khóa ngoại / giá trị duy nhất (`UNIQUE`). |
| `\|\|--o{` | Một – nhiều: một bản ghi bên trái có 0 hoặc nhiều bản ghi bên phải. |
| `\|\|--\|{` | Một – nhiều, bắt buộc có ít nhất 1 (một đơn có ít nhất 1 dòng hàng). |
| `\|\|--o\|` | Một – không hoặc một (một tài khoản sở hữu tối đa một hồ sơ nhà cung cấp). |
| `\|o--o{` | Khóa ngoại có thể để trống (`NULL`), ví dụ dòng hàng chưa được gán lô. |

```mermaid
erDiagram
    nguoi_dung {
        bigint id PK
        varchar email UK
        varchar mat_khau_hash "bcrypt, không trả về client"
        varchar ho_ten
        varchar sdt
        varchar vai_tro "QUAN_TRI / NHAN_VIEN / NHA_CUNG_CAP / KHACH"
        boolean bi_khoa
        timestamptz tao_luc
    }
    vung_nguyen_lieu {
        bigint id PK
        varchar ten UK
        text mo_ta
        numeric vi_do
        numeric kinh_do
    }
    nha_cung_cap {
        bigint id PK
        bigint nguoi_dung_id FK, UK "tài khoản sở hữu hồ sơ"
        bigint vung_id FK
        varchar ten
        varchar nguoi_dai_dien
        varchar sdt
        text dia_chi
        varchar trang_thai_duyet "CHO_DUYET / DA_DUYET / TU_CHOI"
        text ly_do_tu_choi "bắt buộc khi TU_CHOI"
        bigint nguoi_duyet_id FK
        timestamptz duyet_luc
        timestamptz tao_luc
    }
    anh_co_so {
        bigint id PK
        bigint nha_cung_cap_id FK
        text anh_url "URL Supabase Storage"
    }
    chung_nhan {
        bigint id PK
        bigint nha_cung_cap_id FK
        varchar loai "OCOP / VIETGAP / KHAC"
        varchar so_hieu
        smallint hang_sao "3 đến 5, với chứng nhận OCOP"
        date ngay_cap
        date ngay_het_han
        text anh_url
    }
    san_pham {
        bigint id PK
        bigint nha_cung_cap_id FK
        bigint chung_nhan_id FK "chứng nhận căn cứ"
        varchar ten
        text mo_ta
        numeric gia "giá hiện hành"
        smallint hang_sao_de_nghi "do nhà cung cấp đề nghị"
        smallint hang_sao "do Quản trị chốt khi duyệt"
        varchar trang_thai_duyet "CHO_DUYET / DA_DUYET / TU_CHOI"
        text ly_do_tu_choi
        bigint nguoi_duyet_id FK
        timestamptz tao_luc
    }
    anh_san_pham {
        bigint id PK
        bigint san_pham_id FK
        text anh_url
        smallint thu_tu "0 là ảnh bìa"
    }
    lo_san_xuat {
        bigint id PK
        bigint san_pham_id FK
        bigint vung_id FK "vùng nguyên liệu của lô"
        varchar ma_truy_xuat UK "ngẫu nhiên, khó đoán"
        date ngay_sx
        date han_sd
        int so_luong
        int so_luong_con
        varchar nguoi_san_xuat
        text ghi_chu
        bigint nguoi_tao_id FK
        timestamptz tao_luc
    }
    anh_hien_truong {
        bigint id PK
        bigint lo_id FK
        text anh_url
    }
    buoc_truy_xuat {
        bigint id PK
        bigint lo_id FK
        smallint thu_tu "UNIQUE cùng lo_id"
        varchar ten_buoc
        text mo_ta
        timestamptz thoi_diem
        text anh_url
    }
    don_hang {
        bigint id PK
        varchar ma_don UK
        bigint khach_id FK
        text dia_chi_giao
        varchar sdt_nhan
        varchar hinh_thuc_giao "TIEU_CHUAN / NHANH / NHAN_TAI_DIEM"
        numeric phi_giao
        numeric tong_tien "máy chủ tính"
        varchar trang_thai "CHO_XAC_NHAN ... DA_NHAN / DA_HUY"
        timestamptz tao_luc
        timestamptz nhan_luc
    }
    chi_tiet_don {
        bigint id PK
        bigint don_hang_id FK
        bigint san_pham_id FK
        bigint lo_id FK "lô thực tế đã giao, NULL khi chưa gán"
        int so_luong
        numeric don_gia "giá tại lúc đặt"
    }
    danh_gia {
        bigint id PK
        bigint nguoi_dung_id FK
        bigint san_pham_id FK
        bigint don_hang_id FK "đơn đã nhận làm căn cứ"
        smallint so_sao "1 đến 5"
        text noi_dung
        timestamptz tao_luc
    }
    anh_danh_gia {
        bigint id PK
        bigint danh_gia_id FK
        text anh_url
    }
    bao_cao_vi_pham {
        bigint id PK
        bigint nguoi_bao_id FK
        bigint san_pham_id FK
        bigint lo_id FK "có thể NULL"
        varchar loai "NGHI_GIA / SAI_MO_TA / QR_KHONG_KHOP / KHAC"
        text noi_dung
        text anh_url
        varchar trang_thai "MOI / DANG_XAC_MINH / DA_XU_LY / BAC_BO"
        text huong_xu_ly
        text phan_hoi
        bigint nguoi_xu_ly_id FK
        timestamptz tao_luc
    }
    yeu_thich {
        bigint nguoi_dung_id PK, FK
        bigint san_pham_id PK, FK
        timestamptz tao_luc
    }
    theo_doi_nha_cung_cap {
        bigint nguoi_dung_id PK, FK
        bigint nha_cung_cap_id PK, FK
        timestamptz tao_luc
    }

    nguoi_dung ||--o| nha_cung_cap : "sở hữu hồ sơ"
    nguoi_dung |o--o{ nha_cung_cap : "duyệt"
    vung_nguyen_lieu ||--o{ nha_cung_cap : "thuộc vùng"
    nha_cung_cap ||--o{ anh_co_so : "có ảnh cơ sở"
    nha_cung_cap ||--o{ chung_nhan : "được cấp"
    nha_cung_cap ||--o{ san_pham : "cung cấp"
    chung_nhan |o--o{ san_pham : "căn cứ hạng sao"
    nguoi_dung |o--o{ san_pham : "duyệt"
    san_pham ||--o{ anh_san_pham : "có ảnh"
    san_pham ||--o{ lo_san_xuat : "sản xuất thành"
    vung_nguyen_lieu ||--o{ lo_san_xuat : "nguyên liệu từ"
    nguoi_dung ||--o{ lo_san_xuat : "tạo lô"
    lo_san_xuat ||--o{ buoc_truy_xuat : "có hành trình"
    lo_san_xuat ||--o{ anh_hien_truong : "có ảnh hiện trường"
    nguoi_dung ||--o{ don_hang : "đặt"
    don_hang ||--|{ chi_tiet_don : "gồm"
    san_pham ||--o{ chi_tiet_don : "được mua"
    lo_san_xuat |o--o{ chi_tiet_don : "giao từ lô"
    nguoi_dung ||--o{ danh_gia : "viết"
    san_pham ||--o{ danh_gia : "được đánh giá"
    don_hang ||--o{ danh_gia : "căn cứ"
    danh_gia ||--o{ anh_danh_gia : "kèm ảnh"
    nguoi_dung ||--o{ bao_cao_vi_pham : "gửi"
    nguoi_dung |o--o{ bao_cao_vi_pham : "xử lý"
    san_pham ||--o{ bao_cao_vi_pham : "bị báo cáo"
    lo_san_xuat |o--o{ bao_cao_vi_pham : "lô bị báo cáo"
    nguoi_dung ||--o{ yeu_thich : "lưu"
    san_pham ||--o{ yeu_thich : "được lưu"
    nguoi_dung ||--o{ theo_doi_nha_cung_cap : "theo dõi"
    nha_cung_cap ||--o{ theo_doi_nha_cung_cap : "được theo dõi"
```

### Giải thích các điểm chính

- **17 bảng**, đều nối bằng khóa ngoại thật, vượt mức tối thiểu 8 bảng của đề. Ảnh chỉ lưu URL trên Supabase Storage, không lưu base64 trong CSDL.
- **Sản phẩm khác lô.** `san_pham` là mặt hàng chung; `lo_san_xuat` là từng đợt sản xuất, có `ma_truy_xuat` riêng và `buoc_truy_xuat` riêng. `GET /truy-xuat/:maTruyXuat` tìm theo mã của lô, nên quét QR lô A chỉ trả hành trình của lô A.
- **Mã truy xuất khó đoán:** máy chủ sinh ngẫu nhiên (ví dụ 16 ký tự từ `crypto.randomBytes`), có `UNIQUE`; không dùng `id` tăng dần làm mã.
- **Người dùng và vai trò:** một bảng `nguoi_dung` với cột `vai_tro`. `QUAN_TRI` và `NHAN_VIEN` dùng app Admin; `KHACH` và `NHA_CUNG_CAP` dùng app Client (đề xuất). `nha_cung_cap.nguoi_dung_id` có `UNIQUE` nên một tài khoản chỉ sở hữu một hồ sơ. Quyền do backend kiểm tra theo `vai_tro` trong JWT.
- **Duyệt:** `nha_cung_cap` và `san_pham` có `trang_thai_duyet`, `ly_do_tu_choi`, `nguoi_duyet_id`. Đề xuất ràng buộc `CHECK`: khi `TU_CHOI` thì `ly_do_tu_choi` không được trống. Nhà cung cấp chỉ gửi `hang_sao_de_nghi`; `hang_sao` chính thức do Quản trị chốt.
- **Đơn và lô đã giao:** `chi_tiet_don.lo_id` ghi lô thực tế đã giao, có thể `NULL` khi đơn mới đặt. Đề xuất: backend chỉ cho chuyển đơn sang `DANG_GIAO` khi mọi dòng đã có lô. Nếu một dòng phải giao từ nhiều lô, tách thành nhiều dòng cùng `san_pham_id`; quy tắc này cần nhóm chốt.
- **Giá và tồn kho:** `chi_tiet_don.don_gia` lưu giá tại lúc đặt; `don_hang.tong_tien` do máy chủ tính. Tạo đơn, tạo các dòng và trừ `so_luong_con` của lô nằm trong một transaction.
- **Ràng buộc đề xuất khác:** `CHECK` cho `hang_sao` (3–5), `so_sao` (1–5), `so_luong > 0`, `gia >= 0`, `han_sd > ngay_sx`; `UNIQUE (lo_id, thu_tu)` cho bước truy xuất; `UNIQUE (nguoi_dung_id, san_pham_id, don_hang_id)` cho đánh giá. Backend kiểm tra thêm: chỉ được đánh giá khi đơn đã ở `DA_NHAN` và có chứa sản phẩm đó.
- **Giỏ hàng** chưa có bảng: đề xuất lưu trên máy bằng `shared_preferences`, giá và tồn kiểm tra lại khi đặt. Nếu nhóm muốn giỏ đồng bộ nhiều thiết bị thì thêm bảng `gio_hang`.
- Tên các giá trị trạng thái (đơn, báo cáo, chứng nhận) là đề xuất theo [Rule](Rule.md), chưa phải yêu cầu chính thức của đề.
