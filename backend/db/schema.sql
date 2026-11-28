-- Schema CSDL đề 05: Sàn đặc sản vùng và sản phẩm OCOP.
-- Chạy được nhiều lần: xóa các bảng cũ rồi tạo lại (MẤT TOÀN BỘ DỮ LIỆU).
-- Chỉ chạy trên CSDL dành riêng cho đồ án. Sau đó chạy seed.sql.
--
-- Các trạng thái và quy tắc ghi "Đề xuất" trong docs/development/Design_decisions.md
-- chưa được giảng viên xác nhận.

SET client_min_messages = warning;

BEGIN;

DROP TABLE IF EXISTS
  order_status_history,
  review_images,
  reviews,
  issue_reports,
  order_items,
  orders,
  cart_items,
  product_favorites,
  supplier_follows,
  traceability_steps,
  production_batches,
  products,
  certificates,
  suppliers,
  users,
  sourcing_regions
CASCADE;

-- ---------------------------------------------------------------------------
-- Danh mục
-- ---------------------------------------------------------------------------

CREATE TABLE sourcing_regions (
  id          SERIAL PRIMARY KEY,
  name         VARCHAR(120) NOT NULL UNIQUE,
  description       TEXT,
  latitude       NUMERIC(9, 6) CHECK (latitude BETWEEN -90 AND 90),
  longitude     NUMERIC(9, 6) CHECK (longitude BETWEEN -180 AND 180)
);

CREATE TABLE users (
  id              SERIAL PRIMARY KEY,
  email           VARCHAR(255) NOT NULL UNIQUE CHECK (email = lower(email)),
  password_hash   VARCHAR(100) NOT NULL,
  full_name          VARCHAR(120) NOT NULL,
  phone_number   VARCHAR(20),
  role         VARCHAR(20)  NOT NULL DEFAULT 'KHACH'
                  CHECK (role IN ('QUAN_TRI', 'NHAN_VIEN', 'KHACH', 'NHA_CUNG_CAP')),
  is_active  BOOLEAN      NOT NULL DEFAULT TRUE,
  created_at         TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE TABLE suppliers (
  id                SERIAL PRIMARY KEY,
  name               VARCHAR(200) NOT NULL,
  representative_name    VARCHAR(120) NOT NULL,
  phone_number     VARCHAR(20)  NOT NULL,
  address           TEXT         NOT NULL,
  sourcing_region_id           INTEGER      NOT NULL REFERENCES sourcing_regions (id),
  facility_image_url     TEXT,
  approval_status  VARCHAR(20)  NOT NULL DEFAULT 'CHO_DUYET'
                    CHECK (approval_status IN ('CHO_DUYET', 'DA_DUYET', 'TU_CHOI')),
  rejection_reason     TEXT,
  reviewed_by_user_id    INTEGER REFERENCES users (id),
  reviewed_at         TIMESTAMPTZ,
  created_by_user_id      INTEGER REFERENCES users (id),
  -- Tài khoản NHA_CUNG_CAP sở hữu hồ sơ (gửi hồ sơ, sản phẩm từ app Client). NULL nếu nhân sự nhập.
  -- UNIQUE: mỗi tài khoản nhà cung cấp chỉ có một hồ sơ.
  account_id      INTEGER UNIQUE REFERENCES users (id),
  created_at           TIMESTAMPTZ  NOT NULL DEFAULT now(),
  CONSTRAINT suppliers_rejection_reason_check
    CHECK (approval_status <> 'TU_CHOI' OR rejection_reason IS NOT NULL)
);
CREATE INDEX suppliers_sourcing_region_id_idx ON suppliers (sourcing_region_id);

CREATE TABLE certificates (
  id               SERIAL PRIMARY KEY,
  supplier_id  INTEGER     NOT NULL REFERENCES suppliers (id) ON DELETE CASCADE,
  certificate_type             VARCHAR(60) NOT NULL,
  certificate_number          VARCHAR(80) NOT NULL,
  issued_on         DATE        NOT NULL,
  expires_on     DATE,
  image_url          TEXT,
  UNIQUE (certificate_type, certificate_number),
  CHECK (expires_on IS NULL OR expires_on > issued_on)
);
CREATE INDEX certificates_supplier_id_idx ON certificates (supplier_id);

CREATE TABLE products (
  id                SERIAL PRIMARY KEY,
  supplier_id   INTEGER      NOT NULL REFERENCES suppliers (id),
  name               VARCHAR(200) NOT NULL,
  description             TEXT,
  unit       VARCHAR(40)  NOT NULL DEFAULT 'gói',
  -- Giá tính bằng đồng (VND), số nguyên.
  price_vnd               BIGINT       NOT NULL CHECK (price_vnd > 0),
  -- Hạng OCOP do quản trị chốt khi duyệt.
  ocop_rating          SMALLINT     CHECK (ocop_rating BETWEEN 3 AND 5),
  image_url           TEXT,
  approval_status  VARCHAR(20)  NOT NULL DEFAULT 'CHO_DUYET'
                    CHECK (approval_status IN ('CHO_DUYET', 'DA_DUYET', 'TU_CHOI')),
  rejection_reason     TEXT,
  reviewed_by_user_id    INTEGER REFERENCES users (id),
  reviewed_at         TIMESTAMPTZ,
  created_by_user_id      INTEGER REFERENCES users (id),
  created_at           TIMESTAMPTZ  NOT NULL DEFAULT now(),
  CONSTRAINT products_approved_rating_check
    CHECK (approval_status <> 'DA_DUYET' OR ocop_rating IS NOT NULL),
  CONSTRAINT products_rejection_reason_check
    CHECK (approval_status <> 'TU_CHOI' OR rejection_reason IS NOT NULL)
);
CREATE INDEX products_supplier_id_idx ON products (supplier_id);
CREATE INDEX products_approval_status_ocop_rating_idx ON products (approval_status, ocop_rating);

-- ---------------------------------------------------------------------------
-- Truy xuất nguồn gốc theo lô
-- ---------------------------------------------------------------------------

CREATE TABLE production_batches (
  id                  SERIAL PRIMARY KEY,
  product_id         INTEGER     NOT NULL REFERENCES products (id),
  -- Mã in trên QR: 20 ký tự hex in hoa (80 bit ngẫu nhiên), do backend sinh.
  traceability_code        CHAR(20)    NOT NULL UNIQUE CHECK (traceability_code ~ '^[0-9A-F]{20}$'),
  produced_on       DATE        NOT NULL,
  expires_on         DATE        NOT NULL,
  quantity            INTEGER     NOT NULL CHECK (quantity > 0),
  -- Số lượng còn có thể bán; giảm khi đặt đơn, tăng lại khi hủy đơn.
  available_quantity        INTEGER     NOT NULL CHECK (available_quantity >= 0),
  sourcing_region_id INTEGER     NOT NULL REFERENCES sourcing_regions (id),
  producer_name      VARCHAR(120) NOT NULL,
  site_image_url TEXT,
  notes             TEXT,
  created_by_user_id        INTEGER REFERENCES users (id),
  created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
  CHECK (expires_on > produced_on),
  CHECK (available_quantity <= quantity),
  -- Cho phép order_items tham chiếu (id, san_pham_id) để bảo đảm lô thuộc đúng sản phẩm.
  UNIQUE (id, product_id)
);
CREATE INDEX production_batches_product_id_idx ON production_batches (product_id);
CREATE INDEX production_batches_sourcing_region_id_idx ON production_batches (sourcing_region_id);

CREATE TABLE traceability_steps (
  id         SERIAL PRIMARY KEY,
  batch_id      INTEGER      NOT NULL REFERENCES production_batches (id) ON DELETE CASCADE,
  position     SMALLINT     NOT NULL CHECK (position > 0),
  name   VARCHAR(120) NOT NULL,
  description      TEXT,
  occurred_at  TIMESTAMPTZ  NOT NULL,
  image_url    TEXT,
  UNIQUE (batch_id, position)
);

-- ---------------------------------------------------------------------------
-- Mua hàng
-- ---------------------------------------------------------------------------

CREATE TABLE cart_items (
  user_id  INTEGER NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  product_id    INTEGER NOT NULL REFERENCES products (id) ON DELETE CASCADE,
  quantity       INTEGER NOT NULL CHECK (quantity > 0),
  added_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, product_id)
);

CREATE TABLE orders (
  id               SERIAL PRIMARY KEY,
  customer_id         INTEGER      NOT NULL REFERENCES users (id),
  status       VARCHAR(20)  NOT NULL DEFAULT 'CHO_XAC_NHAN'
                   CHECK (status IN ('CHO_XAC_NHAN', 'DA_XAC_NHAN', 'DANG_GIAO',
                                         'DA_GIAO', 'DA_NHAN', 'DA_HUY')),
  delivery_method   VARCHAR(20)  NOT NULL
                   CHECK (delivery_method IN ('TIEU_CHUAN', 'NHANH', 'NHAN_TAI_CHO')),
  delivery_fee_vnd         BIGINT       NOT NULL DEFAULT 0 CHECK (delivery_fee_vnd >= 0),
  subtotal_vnd        BIGINT       NOT NULL CHECK (subtotal_vnd >= 0),
  total_vnd        BIGINT       NOT NULL CHECK (total_vnd >= 0),
  recipient_name   VARCHAR(120) NOT NULL,
  recipient_phone   VARCHAR(20)  NOT NULL,
  delivery_address     TEXT         NOT NULL,
  notes          TEXT,
  created_at          TIMESTAMPTZ  NOT NULL DEFAULT now(),
  updated_at     TIMESTAMPTZ  NOT NULL DEFAULT now(),
  CHECK (total_vnd = subtotal_vnd + delivery_fee_vnd)
);
CREATE INDEX orders_customer_id_idx ON orders (customer_id);
CREATE INDEX orders_status_idx ON orders (status);

-- Một dòng sản phẩm có thể được giao từ nhiều lô: mỗi lô là một dòng chi tiết.
CREATE TABLE order_items (
  id           SERIAL PRIMARY KEY,
  order_id  INTEGER NOT NULL REFERENCES orders (id) ON DELETE CASCADE,
  product_id  INTEGER NOT NULL,
  batch_id        INTEGER NOT NULL,
  quantity     INTEGER NOT NULL CHECK (quantity > 0),
  -- Giá tại thời điểm đặt, lấy từ CSDL chứ không lấy từ client.
  unit_price_vnd      BIGINT  NOT NULL CHECK (unit_price_vnd > 0),
  UNIQUE (order_id, batch_id),
  FOREIGN KEY (batch_id, product_id) REFERENCES production_batches (id, product_id)
);
CREATE INDEX order_items_batch_id_idx ON order_items (batch_id);
CREATE INDEX order_items_product_id_idx ON order_items (product_id);

CREATE TABLE order_status_history (
  id            SERIAL PRIMARY KEY,
  order_id   INTEGER     NOT NULL REFERENCES orders (id) ON DELETE CASCADE,
  status    VARCHAR(20) NOT NULL,
  notes       TEXT,
  changed_by_user_id INTEGER REFERENCES users (id),
  changed_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX order_status_history_order_id_idx ON order_status_history (order_id);

-- ---------------------------------------------------------------------------
-- Tương tác của khách
-- ---------------------------------------------------------------------------

CREATE TABLE reviews (
  id           SERIAL PRIMARY KEY,
  customer_id     INTEGER  NOT NULL REFERENCES users (id),
  product_id  INTEGER  NOT NULL REFERENCES products (id),
  order_id  INTEGER  NOT NULL REFERENCES orders (id),
  rating       SMALLINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comment     TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (customer_id, product_id, order_id)
);
CREATE INDEX reviews_product_id_idx ON reviews (product_id);

CREATE TABLE review_images (
  id           SERIAL PRIMARY KEY,
  review_id  INTEGER NOT NULL REFERENCES reviews (id) ON DELETE CASCADE,
  image_url      TEXT    NOT NULL
);

CREATE TABLE issue_reports (
  id              SERIAL PRIMARY KEY,
  reporter_id    INTEGER     NOT NULL REFERENCES users (id),
  product_id     INTEGER     NOT NULL,
  batch_id           INTEGER,
  report_type            VARCHAR(20) NOT NULL CHECK (report_type IN ('HANG_GIA', 'SAI_MO_TA', 'KHAC')),
  description        TEXT        NOT NULL,
  image_url         TEXT,
  status      VARCHAR(20) NOT NULL DEFAULT 'MOI'
                  CHECK (status IN ('MOI', 'DANG_XU_LY', 'DA_XU_LY', 'BAC_BO')),
  resolution   TEXT,
  handled_by_user_id  INTEGER REFERENCES users (id),
  handled_at       TIMESTAMPTZ,
  created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
  FOREIGN KEY (product_id) REFERENCES products (id),
  FOREIGN KEY (batch_id, product_id) REFERENCES production_batches (id, product_id)
);
CREATE INDEX issue_reports_status_idx ON issue_reports (status);

CREATE TABLE product_favorites (
  user_id  INTEGER NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  product_id    INTEGER NOT NULL REFERENCES products (id) ON DELETE CASCADE,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, product_id)
);

CREATE TABLE supplier_follows (
  user_id    INTEGER NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  supplier_id  INTEGER NOT NULL REFERENCES suppliers (id) ON DELETE CASCADE,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, supplier_id)
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
    'sourcing_regions', 'users', 'suppliers', 'certificates', 'products',
    'production_batches', 'traceability_steps', 'cart_items', 'orders', 'order_items',
    'order_status_history', 'reviews', 'review_images', 'issue_reports',
    'product_favorites', 'supplier_follows'
  ] LOOP
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', t);
  END LOOP;
END $$;

-- The deployed backend can use the old names during the rollout.
-- These views write through to the same tables and use the caller’s RLS permissions.

CREATE VIEW public.vung_nguyen_lieu WITH (security_invoker = true) AS
SELECT id, name AS ten, description AS mo_ta,
       latitude AS vi_do, longitude AS kinh_do
FROM public.sourcing_regions;

CREATE VIEW public.nguoi_dung WITH (security_invoker = true) AS
SELECT id, email, password_hash AS mat_khau_hash,
       full_name AS ho_ten, phone_number AS so_dien_thoai, role AS vai_tro,
       is_active AS dang_hoat_dong, created_at AS tao_luc
FROM public.users;

CREATE VIEW public.nha_cung_cap WITH (security_invoker = true) AS
SELECT id, name AS ten, representative_name AS nguoi_dai_dien,
       phone_number AS so_dien_thoai, address AS dia_chi, sourcing_region_id AS vung_id,
       facility_image_url AS anh_co_so_url, approval_status AS trang_thai_duyet, rejection_reason AS ly_do_tu_choi,
       reviewed_by_user_id AS nguoi_duyet_id, reviewed_at AS duyet_luc, created_by_user_id AS nguoi_tao_id,
       account_id AS tai_khoan_id, created_at AS tao_luc
FROM public.suppliers;

CREATE VIEW public.chung_nhan WITH (security_invoker = true) AS
SELECT id, supplier_id AS nha_cung_cap_id, certificate_type AS loai,
       certificate_number AS so_hieu, issued_on AS ngay_cap, expires_on AS ngay_het_han,
       image_url AS anh_url
FROM public.certificates;

CREATE VIEW public.san_pham WITH (security_invoker = true) AS
SELECT id, supplier_id AS nha_cung_cap_id, name AS ten,
       description AS mo_ta, unit AS don_vi_tinh, price_vnd AS gia,
       ocop_rating AS hang_sao, image_url AS anh_url, approval_status AS trang_thai_duyet,
       rejection_reason AS ly_do_tu_choi, reviewed_by_user_id AS nguoi_duyet_id, reviewed_at AS duyet_luc,
       created_by_user_id AS nguoi_tao_id, created_at AS tao_luc
FROM public.products;

CREATE VIEW public.lo_san_xuat WITH (security_invoker = true) AS
SELECT id, product_id AS san_pham_id, traceability_code AS ma_truy_xuat,
       produced_on AS ngay_san_xuat, expires_on AS han_su_dung, quantity AS so_luong,
       available_quantity AS so_luong_con, sourcing_region_id AS vung_nguyen_lieu_id, producer_name AS nguoi_san_xuat,
       site_image_url AS anh_hien_truong_url, notes AS ghi_chu, created_by_user_id AS nguoi_tao_id,
       created_at AS tao_luc
FROM public.production_batches;

CREATE VIEW public.buoc_truy_xuat WITH (security_invoker = true) AS
SELECT id, batch_id AS lo_id, position AS thu_tu,
       name AS ten_buoc, description AS mo_ta, occurred_at AS thoi_diem,
       image_url AS anh_url
FROM public.traceability_steps;

CREATE VIEW public.gio_hang WITH (security_invoker = true) AS
SELECT user_id AS nguoi_dung_id, product_id AS san_pham_id, quantity AS so_luong,
       added_at AS them_luc
FROM public.cart_items;

CREATE VIEW public.don_hang WITH (security_invoker = true) AS
SELECT id, customer_id AS khach_id, status AS trang_thai,
       delivery_method AS hinh_thuc_giao, delivery_fee_vnd AS phi_giao, subtotal_vnd AS tien_hang,
       total_vnd AS tong_tien, recipient_name AS ten_nguoi_nhan, recipient_phone AS sdt_nguoi_nhan,
       delivery_address AS dia_chi_giao, notes AS ghi_chu, created_at AS tao_luc,
       updated_at AS cap_nhat_luc
FROM public.orders;

CREATE VIEW public.chi_tiet_don WITH (security_invoker = true) AS
SELECT id, order_id AS don_hang_id, product_id AS san_pham_id,
       batch_id AS lo_id, quantity AS so_luong, unit_price_vnd AS don_gia
FROM public.order_items;

CREATE VIEW public.lich_su_trang_thai_don WITH (security_invoker = true) AS
SELECT id, order_id AS don_hang_id, status AS trang_thai,
       notes AS ghi_chu, changed_by_user_id AS nguoi_thuc_hien_id, changed_at AS thoi_diem
FROM public.order_status_history;

CREATE VIEW public.danh_gia WITH (security_invoker = true) AS
SELECT id, customer_id AS khach_id, product_id AS san_pham_id,
       order_id AS don_hang_id, rating AS so_sao, comment AS noi_dung,
       created_at AS tao_luc
FROM public.reviews;

CREATE VIEW public.anh_danh_gia WITH (security_invoker = true) AS
SELECT id, review_id AS danh_gia_id, image_url AS anh_url
FROM public.review_images;

CREATE VIEW public.bao_cao_vi_pham WITH (security_invoker = true) AS
SELECT id, reporter_id AS nguoi_bao_id, product_id AS san_pham_id,
       batch_id AS lo_id, report_type AS loai, description AS noi_dung,
       image_url AS anh_url, status AS trang_thai, resolution AS ket_qua_xu_ly,
       handled_by_user_id AS nguoi_xu_ly_id, handled_at AS xu_ly_luc, created_at AS tao_luc
FROM public.issue_reports;

CREATE VIEW public.yeu_thich WITH (security_invoker = true) AS
SELECT user_id AS nguoi_dung_id, product_id AS san_pham_id, created_at AS tao_luc
FROM public.product_favorites;

CREATE VIEW public.theo_doi_nha_cung_cap WITH (security_invoker = true) AS
SELECT user_id AS nguoi_dung_id, supplier_id AS nha_cung_cap_id, created_at AS tao_luc
FROM public.supplier_follows;

REVOKE ALL ON TABLE
  public.vung_nguyen_lieu,
  public.nguoi_dung,
  public.nha_cung_cap,
  public.chung_nhan,
  public.san_pham,
  public.lo_san_xuat,
  public.buoc_truy_xuat,
  public.gio_hang,
  public.don_hang,
  public.chi_tiet_don,
  public.lich_su_trang_thai_don,
  public.danh_gia,
  public.anh_danh_gia,
  public.bao_cao_vi_pham,
  public.yeu_thich,
  public.theo_doi_nha_cung_cap
FROM PUBLIC;

DO $revoke_view_access$
DECLARE
  role_name text;
BEGIN
  FOREACH role_name IN ARRAY ARRAY['anon', 'authenticated', 'service_role'] LOOP
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = role_name) THEN
      EXECUTE format('REVOKE ALL ON TABLE
  public.vung_nguyen_lieu,
  public.nguoi_dung,
  public.nha_cung_cap,
  public.chung_nhan,
  public.san_pham,
  public.lo_san_xuat,
  public.buoc_truy_xuat,
  public.gio_hang,
  public.don_hang,
  public.chi_tiet_don,
  public.lich_su_trang_thai_don,
  public.danh_gia,
  public.anh_danh_gia,
  public.bao_cao_vi_pham,
  public.yeu_thich,
  public.theo_doi_nha_cung_cap
FROM %I', role_name);
    END IF;
  END LOOP;
END
$revoke_view_access$;

COMMIT;
