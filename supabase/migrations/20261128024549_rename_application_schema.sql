-- Rename application tables without rewriting rows.
-- Keep danh_gia as a table until the Render backend uses the explicit review GROUP BY.
-- Both backend versions can read and write through the same underlying tables in this phase.
BEGIN;
SET LOCAL lock_timeout = '5s';

ALTER TABLE public.vung_nguyen_lieu RENAME TO sourcing_regions;
ALTER TABLE public.sourcing_regions RENAME COLUMN ten TO name;
ALTER TABLE public.sourcing_regions RENAME COLUMN mo_ta TO description;
ALTER TABLE public.sourcing_regions RENAME COLUMN vi_do TO latitude;
ALTER TABLE public.sourcing_regions RENAME COLUMN kinh_do TO longitude;
ALTER TABLE public.sourcing_regions RENAME CONSTRAINT vung_nguyen_lieu_kinh_do_check TO sourcing_regions_longitude_check;
ALTER TABLE public.sourcing_regions RENAME CONSTRAINT vung_nguyen_lieu_pkey TO sourcing_regions_pkey;
ALTER TABLE public.sourcing_regions RENAME CONSTRAINT vung_nguyen_lieu_ten_key TO sourcing_regions_name_key;
ALTER TABLE public.sourcing_regions RENAME CONSTRAINT vung_nguyen_lieu_vi_do_check TO sourcing_regions_latitude_check;
ALTER SEQUENCE public.vung_nguyen_lieu_id_seq RENAME TO sourcing_regions_id_seq;

ALTER TABLE public.nguoi_dung RENAME TO users;
ALTER TABLE public.users RENAME COLUMN mat_khau_hash TO password_hash;
ALTER TABLE public.users RENAME COLUMN ho_ten TO full_name;
ALTER TABLE public.users RENAME COLUMN so_dien_thoai TO phone_number;
ALTER TABLE public.users RENAME COLUMN vai_tro TO role;
ALTER TABLE public.users RENAME COLUMN dang_hoat_dong TO is_active;
ALTER TABLE public.users RENAME COLUMN tao_luc TO created_at;
ALTER TABLE public.users RENAME CONSTRAINT nguoi_dung_email_check TO users_email_check;
ALTER TABLE public.users RENAME CONSTRAINT nguoi_dung_email_key TO users_email_key;
ALTER TABLE public.users RENAME CONSTRAINT nguoi_dung_pkey TO users_pkey;
ALTER TABLE public.users RENAME CONSTRAINT nguoi_dung_vai_tro_check TO users_role_check;
ALTER SEQUENCE public.nguoi_dung_id_seq RENAME TO users_id_seq;

ALTER TABLE public.nha_cung_cap RENAME TO suppliers;
ALTER TABLE public.suppliers RENAME COLUMN ten TO name;
ALTER TABLE public.suppliers RENAME COLUMN nguoi_dai_dien TO representative_name;
ALTER TABLE public.suppliers RENAME COLUMN so_dien_thoai TO phone_number;
ALTER TABLE public.suppliers RENAME COLUMN dia_chi TO address;
ALTER TABLE public.suppliers RENAME COLUMN vung_id TO sourcing_region_id;
ALTER TABLE public.suppliers RENAME COLUMN anh_co_so_url TO facility_image_url;
ALTER TABLE public.suppliers RENAME COLUMN trang_thai_duyet TO approval_status;
ALTER TABLE public.suppliers RENAME COLUMN ly_do_tu_choi TO rejection_reason;
ALTER TABLE public.suppliers RENAME COLUMN nguoi_duyet_id TO reviewed_by_user_id;
ALTER TABLE public.suppliers RENAME COLUMN duyet_luc TO reviewed_at;
ALTER TABLE public.suppliers RENAME COLUMN nguoi_tao_id TO created_by_user_id;
ALTER TABLE public.suppliers RENAME COLUMN tai_khoan_id TO account_id;
ALTER TABLE public.suppliers RENAME COLUMN tao_luc TO created_at;
ALTER TABLE public.suppliers RENAME CONSTRAINT nha_cung_cap_nguoi_duyet_id_fkey TO suppliers_reviewed_by_user_id_fkey;
ALTER TABLE public.suppliers RENAME CONSTRAINT nha_cung_cap_nguoi_tao_id_fkey TO suppliers_created_by_user_id_fkey;
ALTER TABLE public.suppliers RENAME CONSTRAINT nha_cung_cap_pkey TO suppliers_pkey;
ALTER TABLE public.suppliers RENAME CONSTRAINT nha_cung_cap_tai_khoan_id_fkey TO suppliers_account_id_fkey;
ALTER TABLE public.suppliers RENAME CONSTRAINT nha_cung_cap_tai_khoan_id_key TO suppliers_account_id_key;
ALTER TABLE public.suppliers RENAME CONSTRAINT nha_cung_cap_trang_thai_duyet_check TO suppliers_approval_status_check;
ALTER TABLE public.suppliers RENAME CONSTRAINT nha_cung_cap_tu_choi_co_ly_do TO suppliers_rejection_reason_check;
ALTER TABLE public.suppliers RENAME CONSTRAINT nha_cung_cap_vung_id_fkey TO suppliers_sourcing_region_id_fkey;
ALTER SEQUENCE public.nha_cung_cap_id_seq RENAME TO suppliers_id_seq;

ALTER TABLE public.chung_nhan RENAME TO certificates;
ALTER TABLE public.certificates RENAME COLUMN nha_cung_cap_id TO supplier_id;
ALTER TABLE public.certificates RENAME COLUMN loai TO certificate_type;
ALTER TABLE public.certificates RENAME COLUMN so_hieu TO certificate_number;
ALTER TABLE public.certificates RENAME COLUMN ngay_cap TO issued_on;
ALTER TABLE public.certificates RENAME COLUMN ngay_het_han TO expires_on;
ALTER TABLE public.certificates RENAME COLUMN anh_url TO image_url;
ALTER TABLE public.certificates RENAME CONSTRAINT chung_nhan_check TO certificates_check;
ALTER TABLE public.certificates RENAME CONSTRAINT chung_nhan_nha_cung_cap_id_fkey TO certificates_supplier_id_fkey;
ALTER TABLE public.certificates RENAME CONSTRAINT chung_nhan_pkey TO certificates_pkey;
ALTER SEQUENCE public.chung_nhan_id_seq RENAME TO certificates_id_seq;

ALTER TABLE public.san_pham RENAME TO products;
ALTER TABLE public.products RENAME COLUMN nha_cung_cap_id TO supplier_id;
ALTER TABLE public.products RENAME COLUMN ten TO name;
ALTER TABLE public.products RENAME COLUMN mo_ta TO description;
ALTER TABLE public.products RENAME COLUMN don_vi_tinh TO unit;
ALTER TABLE public.products RENAME COLUMN gia TO price_vnd;
ALTER TABLE public.products RENAME COLUMN hang_sao TO ocop_rating;
ALTER TABLE public.products RENAME COLUMN anh_url TO image_url;
ALTER TABLE public.products RENAME COLUMN trang_thai_duyet TO approval_status;
ALTER TABLE public.products RENAME COLUMN ly_do_tu_choi TO rejection_reason;
ALTER TABLE public.products RENAME COLUMN nguoi_duyet_id TO reviewed_by_user_id;
ALTER TABLE public.products RENAME COLUMN duyet_luc TO reviewed_at;
ALTER TABLE public.products RENAME COLUMN nguoi_tao_id TO created_by_user_id;
ALTER TABLE public.products RENAME COLUMN tao_luc TO created_at;
ALTER TABLE public.products RENAME CONSTRAINT san_pham_da_duyet_co_hang_sao TO products_approved_rating_check;
ALTER TABLE public.products RENAME CONSTRAINT san_pham_gia_check TO products_price_vnd_check;
ALTER TABLE public.products RENAME CONSTRAINT san_pham_hang_sao_check TO products_ocop_rating_check;
ALTER TABLE public.products RENAME CONSTRAINT san_pham_nguoi_duyet_id_fkey TO products_reviewed_by_user_id_fkey;
ALTER TABLE public.products RENAME CONSTRAINT san_pham_nguoi_tao_id_fkey TO products_created_by_user_id_fkey;
ALTER TABLE public.products RENAME CONSTRAINT san_pham_nha_cung_cap_id_fkey TO products_supplier_id_fkey;
ALTER TABLE public.products RENAME CONSTRAINT san_pham_pkey TO products_pkey;
ALTER TABLE public.products RENAME CONSTRAINT san_pham_trang_thai_duyet_check TO products_approval_status_check;
ALTER TABLE public.products RENAME CONSTRAINT san_pham_tu_choi_co_ly_do TO products_rejection_reason_check;
ALTER SEQUENCE public.san_pham_id_seq RENAME TO products_id_seq;

ALTER TABLE public.lo_san_xuat RENAME TO production_batches;
ALTER TABLE public.production_batches RENAME COLUMN san_pham_id TO product_id;
ALTER TABLE public.production_batches RENAME COLUMN ma_truy_xuat TO traceability_code;
ALTER TABLE public.production_batches RENAME COLUMN ngay_san_xuat TO produced_on;
ALTER TABLE public.production_batches RENAME COLUMN han_su_dung TO expires_on;
ALTER TABLE public.production_batches RENAME COLUMN so_luong TO quantity;
ALTER TABLE public.production_batches RENAME COLUMN so_luong_con TO available_quantity;
ALTER TABLE public.production_batches RENAME COLUMN vung_nguyen_lieu_id TO sourcing_region_id;
ALTER TABLE public.production_batches RENAME COLUMN nguoi_san_xuat TO producer_name;
ALTER TABLE public.production_batches RENAME COLUMN anh_hien_truong_url TO site_image_url;
ALTER TABLE public.production_batches RENAME COLUMN ghi_chu TO notes;
ALTER TABLE public.production_batches RENAME COLUMN nguoi_tao_id TO created_by_user_id;
ALTER TABLE public.production_batches RENAME COLUMN tao_luc TO created_at;
ALTER TABLE public.production_batches RENAME CONSTRAINT lo_san_xuat_check TO production_batches_check;
ALTER TABLE public.production_batches RENAME CONSTRAINT lo_san_xuat_check1 TO production_batches_check1;
ALTER TABLE public.production_batches RENAME CONSTRAINT lo_san_xuat_id_san_pham_id_key TO production_batches_id_product_id_key;
ALTER TABLE public.production_batches RENAME CONSTRAINT lo_san_xuat_ma_truy_xuat_check TO production_batches_traceability_code_check;
ALTER TABLE public.production_batches RENAME CONSTRAINT lo_san_xuat_nguoi_tao_id_fkey TO production_batches_created_by_user_id_fkey;
ALTER TABLE public.production_batches RENAME CONSTRAINT lo_san_xuat_pkey TO production_batches_pkey;
ALTER TABLE public.production_batches RENAME CONSTRAINT lo_san_xuat_san_pham_id_fkey TO production_batches_product_id_fkey;
ALTER TABLE public.production_batches RENAME CONSTRAINT lo_san_xuat_so_luong_check TO production_batches_quantity_check;
ALTER TABLE public.production_batches RENAME CONSTRAINT lo_san_xuat_so_luong_con_check TO production_batches_available_quantity_check;
ALTER TABLE public.production_batches RENAME CONSTRAINT lo_san_xuat_vung_nguyen_lieu_id_fkey TO production_batches_sourcing_region_id_fkey;
ALTER SEQUENCE public.lo_san_xuat_id_seq RENAME TO production_batches_id_seq;

ALTER TABLE public.buoc_truy_xuat RENAME TO traceability_steps;
ALTER TABLE public.traceability_steps RENAME COLUMN lo_id TO batch_id;
ALTER TABLE public.traceability_steps RENAME COLUMN thu_tu TO position;
ALTER TABLE public.traceability_steps RENAME COLUMN ten_buoc TO name;
ALTER TABLE public.traceability_steps RENAME COLUMN mo_ta TO description;
ALTER TABLE public.traceability_steps RENAME COLUMN thoi_diem TO occurred_at;
ALTER TABLE public.traceability_steps RENAME COLUMN anh_url TO image_url;
ALTER TABLE public.traceability_steps RENAME CONSTRAINT buoc_truy_xuat_lo_id_fkey TO traceability_steps_batch_id_fkey;
ALTER TABLE public.traceability_steps RENAME CONSTRAINT buoc_truy_xuat_lo_id_thu_tu_key TO traceability_steps_batch_id_position_key;
ALTER TABLE public.traceability_steps RENAME CONSTRAINT buoc_truy_xuat_pkey TO traceability_steps_pkey;
ALTER TABLE public.traceability_steps RENAME CONSTRAINT buoc_truy_xuat_thu_tu_check TO traceability_steps_position_check;
ALTER SEQUENCE public.buoc_truy_xuat_id_seq RENAME TO traceability_steps_id_seq;

ALTER TABLE public.gio_hang RENAME TO cart_items;
ALTER TABLE public.cart_items RENAME COLUMN nguoi_dung_id TO user_id;
ALTER TABLE public.cart_items RENAME COLUMN san_pham_id TO product_id;
ALTER TABLE public.cart_items RENAME COLUMN so_luong TO quantity;
ALTER TABLE public.cart_items RENAME COLUMN them_luc TO added_at;
ALTER TABLE public.cart_items RENAME CONSTRAINT gio_hang_nguoi_dung_id_fkey TO cart_items_user_id_fkey;
ALTER TABLE public.cart_items RENAME CONSTRAINT gio_hang_pkey TO cart_items_pkey;
ALTER TABLE public.cart_items RENAME CONSTRAINT gio_hang_san_pham_id_fkey TO cart_items_product_id_fkey;
ALTER TABLE public.cart_items RENAME CONSTRAINT gio_hang_so_luong_check TO cart_items_quantity_check;

ALTER TABLE public.don_hang RENAME TO orders;
ALTER TABLE public.orders RENAME COLUMN khach_id TO customer_id;
ALTER TABLE public.orders RENAME COLUMN trang_thai TO status;
ALTER TABLE public.orders RENAME COLUMN hinh_thuc_giao TO delivery_method;
ALTER TABLE public.orders RENAME COLUMN phi_giao TO delivery_fee_vnd;
ALTER TABLE public.orders RENAME COLUMN tien_hang TO subtotal_vnd;
ALTER TABLE public.orders RENAME COLUMN tong_tien TO total_vnd;
ALTER TABLE public.orders RENAME COLUMN ten_nguoi_nhan TO recipient_name;
ALTER TABLE public.orders RENAME COLUMN sdt_nguoi_nhan TO recipient_phone;
ALTER TABLE public.orders RENAME COLUMN dia_chi_giao TO delivery_address;
ALTER TABLE public.orders RENAME COLUMN ghi_chu TO notes;
ALTER TABLE public.orders RENAME COLUMN tao_luc TO created_at;
ALTER TABLE public.orders RENAME COLUMN cap_nhat_luc TO updated_at;
ALTER TABLE public.orders RENAME CONSTRAINT don_hang_check TO orders_check;
ALTER TABLE public.orders RENAME CONSTRAINT don_hang_hinh_thuc_giao_check TO orders_delivery_method_check;
ALTER TABLE public.orders RENAME CONSTRAINT don_hang_khach_id_fkey TO orders_customer_id_fkey;
ALTER TABLE public.orders RENAME CONSTRAINT don_hang_phi_giao_check TO orders_delivery_fee_vnd_check;
ALTER TABLE public.orders RENAME CONSTRAINT don_hang_pkey TO orders_pkey;
ALTER TABLE public.orders RENAME CONSTRAINT don_hang_tien_hang_check TO orders_subtotal_vnd_check;
ALTER TABLE public.orders RENAME CONSTRAINT don_hang_tong_tien_check TO orders_total_vnd_check;
ALTER TABLE public.orders RENAME CONSTRAINT don_hang_trang_thai_check TO orders_status_check;
ALTER SEQUENCE public.don_hang_id_seq RENAME TO orders_id_seq;

ALTER TABLE public.chi_tiet_don RENAME TO order_items;
ALTER TABLE public.order_items RENAME COLUMN don_hang_id TO order_id;
ALTER TABLE public.order_items RENAME COLUMN san_pham_id TO product_id;
ALTER TABLE public.order_items RENAME COLUMN lo_id TO batch_id;
ALTER TABLE public.order_items RENAME COLUMN so_luong TO quantity;
ALTER TABLE public.order_items RENAME COLUMN don_gia TO unit_price_vnd;
ALTER TABLE public.order_items RENAME CONSTRAINT chi_tiet_don_don_gia_check TO order_items_unit_price_vnd_check;
ALTER TABLE public.order_items RENAME CONSTRAINT chi_tiet_don_don_hang_id_fkey TO order_items_order_id_fkey;
ALTER TABLE public.order_items RENAME CONSTRAINT chi_tiet_don_don_hang_id_lo_id_key TO order_items_order_id_batch_id_key;
ALTER TABLE public.order_items RENAME CONSTRAINT chi_tiet_don_lo_id_san_pham_id_fkey TO order_items_batch_id_product_id_fkey;
ALTER TABLE public.order_items RENAME CONSTRAINT chi_tiet_don_pkey TO order_items_pkey;
ALTER TABLE public.order_items RENAME CONSTRAINT chi_tiet_don_so_luong_check TO order_items_quantity_check;
ALTER SEQUENCE public.chi_tiet_don_id_seq RENAME TO order_items_id_seq;

ALTER TABLE public.lich_su_trang_thai_don RENAME TO order_status_history;
ALTER TABLE public.order_status_history RENAME COLUMN don_hang_id TO order_id;
ALTER TABLE public.order_status_history RENAME COLUMN trang_thai TO status;
ALTER TABLE public.order_status_history RENAME COLUMN ghi_chu TO notes;
ALTER TABLE public.order_status_history RENAME COLUMN nguoi_thuc_hien_id TO changed_by_user_id;
ALTER TABLE public.order_status_history RENAME COLUMN thoi_diem TO changed_at;
ALTER TABLE public.order_status_history RENAME CONSTRAINT lich_su_trang_thai_don_don_hang_id_fkey TO order_status_history_order_id_fkey;
ALTER TABLE public.order_status_history RENAME CONSTRAINT lich_su_trang_thai_don_nguoi_thuc_hien_id_fkey TO order_status_history_changed_by_user_id_fkey;
ALTER TABLE public.order_status_history RENAME CONSTRAINT lich_su_trang_thai_don_pkey TO order_status_history_pkey;
ALTER SEQUENCE public.lich_su_trang_thai_don_id_seq RENAME TO order_status_history_id_seq;

ALTER TABLE public.anh_danh_gia RENAME TO review_images;
ALTER TABLE public.review_images RENAME COLUMN danh_gia_id TO review_id;
ALTER TABLE public.review_images RENAME COLUMN anh_url TO image_url;
ALTER TABLE public.review_images RENAME CONSTRAINT anh_danh_gia_danh_gia_id_fkey TO review_images_review_id_fkey;
ALTER TABLE public.review_images RENAME CONSTRAINT anh_danh_gia_pkey TO review_images_pkey;
ALTER SEQUENCE public.anh_danh_gia_id_seq RENAME TO review_images_id_seq;

ALTER TABLE public.bao_cao_vi_pham RENAME TO issue_reports;
ALTER TABLE public.issue_reports RENAME COLUMN nguoi_bao_id TO reporter_id;
ALTER TABLE public.issue_reports RENAME COLUMN san_pham_id TO product_id;
ALTER TABLE public.issue_reports RENAME COLUMN lo_id TO batch_id;
ALTER TABLE public.issue_reports RENAME COLUMN loai TO report_type;
ALTER TABLE public.issue_reports RENAME COLUMN noi_dung TO description;
ALTER TABLE public.issue_reports RENAME COLUMN anh_url TO image_url;
ALTER TABLE public.issue_reports RENAME COLUMN trang_thai TO status;
ALTER TABLE public.issue_reports RENAME COLUMN ket_qua_xu_ly TO resolution;
ALTER TABLE public.issue_reports RENAME COLUMN nguoi_xu_ly_id TO handled_by_user_id;
ALTER TABLE public.issue_reports RENAME COLUMN xu_ly_luc TO handled_at;
ALTER TABLE public.issue_reports RENAME COLUMN tao_luc TO created_at;
ALTER TABLE public.issue_reports RENAME CONSTRAINT bao_cao_vi_pham_lo_id_san_pham_id_fkey TO issue_reports_batch_id_product_id_fkey;
ALTER TABLE public.issue_reports RENAME CONSTRAINT bao_cao_vi_pham_loai_check TO issue_reports_report_type_check;
ALTER TABLE public.issue_reports RENAME CONSTRAINT bao_cao_vi_pham_nguoi_bao_id_fkey TO issue_reports_reporter_id_fkey;
ALTER TABLE public.issue_reports RENAME CONSTRAINT bao_cao_vi_pham_nguoi_xu_ly_id_fkey TO issue_reports_handled_by_user_id_fkey;
ALTER TABLE public.issue_reports RENAME CONSTRAINT bao_cao_vi_pham_pkey TO issue_reports_pkey;
ALTER TABLE public.issue_reports RENAME CONSTRAINT bao_cao_vi_pham_san_pham_id_fkey TO issue_reports_product_id_fkey;
ALTER TABLE public.issue_reports RENAME CONSTRAINT bao_cao_vi_pham_trang_thai_check TO issue_reports_status_check;
ALTER SEQUENCE public.bao_cao_vi_pham_id_seq RENAME TO issue_reports_id_seq;

ALTER TABLE public.yeu_thich RENAME TO product_favorites;
ALTER TABLE public.product_favorites RENAME COLUMN nguoi_dung_id TO user_id;
ALTER TABLE public.product_favorites RENAME COLUMN san_pham_id TO product_id;
ALTER TABLE public.product_favorites RENAME COLUMN tao_luc TO created_at;
ALTER TABLE public.product_favorites RENAME CONSTRAINT yeu_thich_nguoi_dung_id_fkey TO product_favorites_user_id_fkey;
ALTER TABLE public.product_favorites RENAME CONSTRAINT yeu_thich_pkey TO product_favorites_pkey;
ALTER TABLE public.product_favorites RENAME CONSTRAINT yeu_thich_san_pham_id_fkey TO product_favorites_product_id_fkey;

ALTER TABLE public.theo_doi_nha_cung_cap RENAME TO supplier_follows;
ALTER TABLE public.supplier_follows RENAME COLUMN nguoi_dung_id TO user_id;
ALTER TABLE public.supplier_follows RENAME COLUMN nha_cung_cap_id TO supplier_id;
ALTER TABLE public.supplier_follows RENAME COLUMN tao_luc TO created_at;
ALTER TABLE public.supplier_follows RENAME CONSTRAINT theo_doi_nha_cung_cap_nguoi_dung_id_fkey TO supplier_follows_user_id_fkey;
ALTER TABLE public.supplier_follows RENAME CONSTRAINT theo_doi_nha_cung_cap_nha_cung_cap_id_fkey TO supplier_follows_supplier_id_fkey;
ALTER TABLE public.supplier_follows RENAME CONSTRAINT theo_doi_nha_cung_cap_pkey TO supplier_follows_pkey;

ALTER INDEX public.nha_cung_cap_vung_idx RENAME TO suppliers_sourcing_region_id_idx;
ALTER INDEX public.chung_nhan_ncc_idx RENAME TO certificates_supplier_id_idx;
ALTER INDEX public.san_pham_ncc_idx RENAME TO products_supplier_id_idx;
ALTER INDEX public.san_pham_trang_thai_idx RENAME TO products_approval_status_ocop_rating_idx;
ALTER INDEX public.lo_san_xuat_san_pham_idx RENAME TO production_batches_product_id_idx;
ALTER INDEX public.lo_san_xuat_vung_idx RENAME TO production_batches_sourcing_region_id_idx;
ALTER INDEX public.don_hang_khach_idx RENAME TO orders_customer_id_idx;
ALTER INDEX public.don_hang_trang_thai_idx RENAME TO orders_status_idx;
ALTER INDEX public.chi_tiet_don_lo_idx RENAME TO order_items_batch_id_idx;
ALTER INDEX public.chi_tiet_don_san_pham_idx RENAME TO order_items_product_id_idx;
ALTER INDEX public.lich_su_don_idx RENAME TO order_status_history_order_id_idx;
ALTER INDEX public.bao_cao_trang_thai_idx RENAME TO issue_reports_status_idx;

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

CREATE VIEW public.reviews WITH (security_invoker = true) AS
SELECT id, khach_id AS customer_id, san_pham_id AS product_id, don_hang_id AS order_id,
       so_sao AS rating, noi_dung AS comment, tao_luc AS created_at
FROM public.danh_gia;

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
  public.reviews,
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
  public.reviews,
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
