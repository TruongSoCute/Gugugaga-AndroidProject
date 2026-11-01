-- Schema CSDL đề 05: Sàn đặc sản vùng và sản phẩm OCOP.
-- Chạy được nhiều lần: xóa các bảng cũ rồi tạo lại (MẤT TOÀN BỘ DỮ LIỆU).
-- Chỉ chạy trên CSDL dành riêng cho đồ án. Sau đó chạy seed.sql.
--
-- Các trạng thái và quy tắc ghi "Đề xuất" trong docs/development/Design_decisions.md
-- chưa được giảng viên xác nhận.

SET client_min_messages = warning;

BEGIN;

DROP TABLE IF EXISTS
  lich_su_trang_thai_don,
  anh_danh_gia,
  danh_gia,
  bao_cao_vi_pham,
  chi_tiet_don,
  don_hang,
  gio_hang,
  yeu_thich,
  theo_doi_nha_cung_cap,
  buoc_truy_xuat,
  lo_san_xuat,
  san_pham,
  chung_nhan,
  nha_cung_cap,
  nguoi_dung,
  vung_nguyen_lieu
CASCADE;

-- ---------------------------------------------------------------------------
-- Danh mục
-- ---------------------------------------------------------------------------

CREATE TABLE vung_nguyen_lieu (
  id          SERIAL PRIMARY KEY,
  ten         VARCHAR(120) NOT NULL UNIQUE,
  mo_ta       TEXT,
  vi_do       NUMERIC(9, 6) CHECK (vi_do BETWEEN -90 AND 90),
  kinh_do     NUMERIC(9, 6) CHECK (kinh_do BETWEEN -180 AND 180)
);

CREATE TABLE nguoi_dung (
  id              SERIAL PRIMARY KEY,
  email           VARCHAR(255) NOT NULL UNIQUE CHECK (email = lower(email)),
  mat_khau_hash   VARCHAR(100) NOT NULL,
  ho_ten          VARCHAR(120) NOT NULL,
  so_dien_thoai   VARCHAR(20),
  vai_tro         VARCHAR(20)  NOT NULL DEFAULT 'KHACH'
                  CHECK (vai_tro IN ('QUAN_TRI', 'NHAN_VIEN', 'KHACH')),
  dang_hoat_dong  BOOLEAN      NOT NULL DEFAULT TRUE,
  tao_luc         TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE TABLE nha_cung_cap (
  id                SERIAL PRIMARY KEY,
  ten               VARCHAR(200) NOT NULL,
  nguoi_dai_dien    VARCHAR(120) NOT NULL,
  so_dien_thoai     VARCHAR(20)  NOT NULL,
  dia_chi           TEXT         NOT NULL,
  vung_id           INTEGER      NOT NULL REFERENCES vung_nguyen_lieu (id),
  anh_co_so_url     TEXT,
  trang_thai_duyet  VARCHAR(20)  NOT NULL DEFAULT 'CHO_DUYET'
                    CHECK (trang_thai_duyet IN ('CHO_DUYET', 'DA_DUYET', 'TU_CHOI')),
  ly_do_tu_choi     TEXT,
  nguoi_duyet_id    INTEGER REFERENCES nguoi_dung (id),
  duyet_luc         TIMESTAMPTZ,
  nguoi_tao_id      INTEGER REFERENCES nguoi_dung (id),
  tao_luc           TIMESTAMPTZ  NOT NULL DEFAULT now(),
  CONSTRAINT nha_cung_cap_tu_choi_co_ly_do
    CHECK (trang_thai_duyet <> 'TU_CHOI' OR ly_do_tu_choi IS NOT NULL)
);
CREATE INDEX nha_cung_cap_vung_idx ON nha_cung_cap (vung_id);

CREATE TABLE chung_nhan (
  id               SERIAL PRIMARY KEY,
  nha_cung_cap_id  INTEGER     NOT NULL REFERENCES nha_cung_cap (id) ON DELETE CASCADE,
  loai             VARCHAR(60) NOT NULL,
  so_hieu          VARCHAR(80) NOT NULL,
  ngay_cap         DATE        NOT NULL,
  ngay_het_han     DATE,
  anh_url          TEXT,
  UNIQUE (loai, so_hieu),
  CHECK (ngay_het_han IS NULL OR ngay_het_han > ngay_cap)
);
CREATE INDEX chung_nhan_ncc_idx ON chung_nhan (nha_cung_cap_id);

CREATE TABLE san_pham (
  id                SERIAL PRIMARY KEY,
  nha_cung_cap_id   INTEGER      NOT NULL REFERENCES nha_cung_cap (id),
  ten               VARCHAR(200) NOT NULL,
  mo_ta             TEXT,
  don_vi_tinh       VARCHAR(40)  NOT NULL DEFAULT 'gói',
  -- Giá tính bằng đồng (VND), số nguyên.
  gia               BIGINT       NOT NULL CHECK (gia > 0),
  -- Hạng OCOP do quản trị chốt khi duyệt.
  hang_sao          SMALLINT     CHECK (hang_sao BETWEEN 3 AND 5),
  anh_url           TEXT,
  trang_thai_duyet  VARCHAR(20)  NOT NULL DEFAULT 'CHO_DUYET'
                    CHECK (trang_thai_duyet IN ('CHO_DUYET', 'DA_DUYET', 'TU_CHOI')),
  ly_do_tu_choi     TEXT,
  nguoi_duyet_id    INTEGER REFERENCES nguoi_dung (id),
  duyet_luc         TIMESTAMPTZ,
  nguoi_tao_id      INTEGER REFERENCES nguoi_dung (id),
  tao_luc           TIMESTAMPTZ  NOT NULL DEFAULT now(),
  CONSTRAINT san_pham_da_duyet_co_hang_sao
    CHECK (trang_thai_duyet <> 'DA_DUYET' OR hang_sao IS NOT NULL),
  CONSTRAINT san_pham_tu_choi_co_ly_do
    CHECK (trang_thai_duyet <> 'TU_CHOI' OR ly_do_tu_choi IS NOT NULL)
);
CREATE INDEX san_pham_ncc_idx ON san_pham (nha_cung_cap_id);
CREATE INDEX san_pham_trang_thai_idx ON san_pham (trang_thai_duyet, hang_sao);

-- ---------------------------------------------------------------------------
-- Truy xuất nguồn gốc theo lô
-- ---------------------------------------------------------------------------

CREATE TABLE lo_san_xuat (
  id                  SERIAL PRIMARY KEY,
  san_pham_id         INTEGER     NOT NULL REFERENCES san_pham (id),
  -- Mã in trên QR: 20 ký tự hex in hoa (80 bit ngẫu nhiên), do backend sinh.
  ma_truy_xuat        CHAR(20)    NOT NULL UNIQUE CHECK (ma_truy_xuat ~ '^[0-9A-F]{20}$'),
  ngay_san_xuat       DATE        NOT NULL,
  han_su_dung         DATE        NOT NULL,
  so_luong            INTEGER     NOT NULL CHECK (so_luong > 0),
  -- Số lượng còn có thể bán; giảm khi đặt đơn, tăng lại khi hủy đơn.
  so_luong_con        INTEGER     NOT NULL CHECK (so_luong_con >= 0),
  vung_nguyen_lieu_id INTEGER     NOT NULL REFERENCES vung_nguyen_lieu (id),
  nguoi_san_xuat      VARCHAR(120) NOT NULL,
  anh_hien_truong_url TEXT,
  ghi_chu             TEXT,
  nguoi_tao_id        INTEGER REFERENCES nguoi_dung (id),
  tao_luc             TIMESTAMPTZ NOT NULL DEFAULT now(),
  CHECK (han_su_dung > ngay_san_xuat),
  CHECK (so_luong_con <= so_luong),
  -- Cho phép chi_tiet_don tham chiếu (id, san_pham_id) để bảo đảm lô thuộc đúng sản phẩm.
  UNIQUE (id, san_pham_id)
);
CREATE INDEX lo_san_xuat_san_pham_idx ON lo_san_xuat (san_pham_id);
CREATE INDEX lo_san_xuat_vung_idx ON lo_san_xuat (vung_nguyen_lieu_id);

CREATE TABLE buoc_truy_xuat (
  id         SERIAL PRIMARY KEY,
  lo_id      INTEGER      NOT NULL REFERENCES lo_san_xuat (id) ON DELETE CASCADE,
  thu_tu     SMALLINT     NOT NULL CHECK (thu_tu > 0),
  ten_buoc   VARCHAR(120) NOT NULL,
  mo_ta      TEXT,
  thoi_diem  TIMESTAMPTZ  NOT NULL,
  anh_url    TEXT,
  UNIQUE (lo_id, thu_tu)
);

-- ---------------------------------------------------------------------------
-- Mua hàng
-- ---------------------------------------------------------------------------

CREATE TABLE gio_hang (
  nguoi_dung_id  INTEGER NOT NULL REFERENCES nguoi_dung (id) ON DELETE CASCADE,
  san_pham_id    INTEGER NOT NULL REFERENCES san_pham (id) ON DELETE CASCADE,
  so_luong       INTEGER NOT NULL CHECK (so_luong > 0),
  them_luc       TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (nguoi_dung_id, san_pham_id)
);

CREATE TABLE don_hang (
  id               SERIAL PRIMARY KEY,
  khach_id         INTEGER      NOT NULL REFERENCES nguoi_dung (id),
  trang_thai       VARCHAR(20)  NOT NULL DEFAULT 'CHO_XAC_NHAN'
                   CHECK (trang_thai IN ('CHO_XAC_NHAN', 'DA_XAC_NHAN', 'DANG_GIAO',
                                         'DA_GIAO', 'DA_NHAN', 'DA_HUY')),
  hinh_thuc_giao   VARCHAR(20)  NOT NULL
                   CHECK (hinh_thuc_giao IN ('TIEU_CHUAN', 'NHANH', 'NHAN_TAI_CHO')),
  phi_giao         BIGINT       NOT NULL DEFAULT 0 CHECK (phi_giao >= 0),
  tien_hang        BIGINT       NOT NULL CHECK (tien_hang >= 0),
  tong_tien        BIGINT       NOT NULL CHECK (tong_tien >= 0),
  ten_nguoi_nhan   VARCHAR(120) NOT NULL,
  sdt_nguoi_nhan   VARCHAR(20)  NOT NULL,
  dia_chi_giao     TEXT         NOT NULL,
  ghi_chu          TEXT,
  tao_luc          TIMESTAMPTZ  NOT NULL DEFAULT now(),
  cap_nhat_luc     TIMESTAMPTZ  NOT NULL DEFAULT now(),
  CHECK (tong_tien = tien_hang + phi_giao)
);
CREATE INDEX don_hang_khach_idx ON don_hang (khach_id);
CREATE INDEX don_hang_trang_thai_idx ON don_hang (trang_thai);

-- Một dòng sản phẩm có thể được giao từ nhiều lô: mỗi lô là một dòng chi tiết.
CREATE TABLE chi_tiet_don (
  id           SERIAL PRIMARY KEY,
  don_hang_id  INTEGER NOT NULL REFERENCES don_hang (id) ON DELETE CASCADE,
  san_pham_id  INTEGER NOT NULL,
  lo_id        INTEGER NOT NULL,
  so_luong     INTEGER NOT NULL CHECK (so_luong > 0),
  -- Giá tại thời điểm đặt, lấy từ CSDL chứ không lấy từ client.
  don_gia      BIGINT  NOT NULL CHECK (don_gia > 0),
  UNIQUE (don_hang_id, lo_id),
  FOREIGN KEY (lo_id, san_pham_id) REFERENCES lo_san_xuat (id, san_pham_id)
);
CREATE INDEX chi_tiet_don_lo_idx ON chi_tiet_don (lo_id);
CREATE INDEX chi_tiet_don_san_pham_idx ON chi_tiet_don (san_pham_id);

CREATE TABLE lich_su_trang_thai_don (
  id            SERIAL PRIMARY KEY,
  don_hang_id   INTEGER     NOT NULL REFERENCES don_hang (id) ON DELETE CASCADE,
  trang_thai    VARCHAR(20) NOT NULL,
  ghi_chu       TEXT,
  nguoi_thuc_hien_id INTEGER REFERENCES nguoi_dung (id),
  thoi_diem     TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX lich_su_don_idx ON lich_su_trang_thai_don (don_hang_id);

-- ---------------------------------------------------------------------------
-- Tương tác của khách
-- ---------------------------------------------------------------------------

CREATE TABLE danh_gia (
  id           SERIAL PRIMARY KEY,
  khach_id     INTEGER  NOT NULL REFERENCES nguoi_dung (id),
  san_pham_id  INTEGER  NOT NULL REFERENCES san_pham (id),
  don_hang_id  INTEGER  NOT NULL REFERENCES don_hang (id),
  so_sao       SMALLINT NOT NULL CHECK (so_sao BETWEEN 1 AND 5),
  noi_dung     TEXT,
  tao_luc      TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (khach_id, san_pham_id, don_hang_id)
);
CREATE INDEX danh_gia_san_pham_idx ON danh_gia (san_pham_id);

CREATE TABLE anh_danh_gia (
  id           SERIAL PRIMARY KEY,
  danh_gia_id  INTEGER NOT NULL REFERENCES danh_gia (id) ON DELETE CASCADE,
  anh_url      TEXT    NOT NULL
);

CREATE TABLE bao_cao_vi_pham (
  id              SERIAL PRIMARY KEY,
  nguoi_bao_id    INTEGER     NOT NULL REFERENCES nguoi_dung (id),
  san_pham_id     INTEGER     NOT NULL,
  lo_id           INTEGER,
  loai            VARCHAR(20) NOT NULL CHECK (loai IN ('HANG_GIA', 'SAI_MO_TA', 'KHAC')),
  noi_dung        TEXT        NOT NULL,
  anh_url         TEXT,
  trang_thai      VARCHAR(20) NOT NULL DEFAULT 'MOI'
                  CHECK (trang_thai IN ('MOI', 'DANG_XU_LY', 'DA_XU_LY', 'BAC_BO')),
  ket_qua_xu_ly   TEXT,
  nguoi_xu_ly_id  INTEGER REFERENCES nguoi_dung (id),
  xu_ly_luc       TIMESTAMPTZ,
  tao_luc         TIMESTAMPTZ NOT NULL DEFAULT now(),
  FOREIGN KEY (san_pham_id) REFERENCES san_pham (id),
  FOREIGN KEY (lo_id, san_pham_id) REFERENCES lo_san_xuat (id, san_pham_id)
);
CREATE INDEX bao_cao_trang_thai_idx ON bao_cao_vi_pham (trang_thai);

CREATE TABLE yeu_thich (
  nguoi_dung_id  INTEGER NOT NULL REFERENCES nguoi_dung (id) ON DELETE CASCADE,
  san_pham_id    INTEGER NOT NULL REFERENCES san_pham (id) ON DELETE CASCADE,
  tao_luc        TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (nguoi_dung_id, san_pham_id)
);

CREATE TABLE theo_doi_nha_cung_cap (
  nguoi_dung_id    INTEGER NOT NULL REFERENCES nguoi_dung (id) ON DELETE CASCADE,
  nha_cung_cap_id  INTEGER NOT NULL REFERENCES nha_cung_cap (id) ON DELETE CASCADE,
  tao_luc          TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (nguoi_dung_id, nha_cung_cap_id)
);

-- ---------------------------------------------------------------------------
-- Supabase tự mở các bảng trong schema public qua REST API (PostgREST) cho khóa
-- anon/authenticated. Hai app chỉ gọi backend Express, nên bật RLS mà không tạo
-- policy để chặn mọi truy cập qua REST API của Supabase (kể cả đọc mat_khau_hash).
-- Backend kết nối bằng chủ sở hữu bảng nên không bị RLS chặn.
-- ---------------------------------------------------------------------------
DO $$
DECLARE t TEXT;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'vung_nguyen_lieu', 'nguoi_dung', 'nha_cung_cap', 'chung_nhan', 'san_pham',
    'lo_san_xuat', 'buoc_truy_xuat', 'gio_hang', 'don_hang', 'chi_tiet_don',
    'lich_su_trang_thai_don', 'danh_gia', 'anh_danh_gia', 'bao_cao_vi_pham',
    'yeu_thich', 'theo_doi_nha_cung_cap'
  ] LOOP
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', t);
  END LOOP;
END $$;

COMMIT;
