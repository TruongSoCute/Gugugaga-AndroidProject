-- Apply after Render serves the backend with the explicit review GROUP BY.
-- The older backend needs the review table's primary key for GROUP BY danh_gia.id.
BEGIN;
SET LOCAL lock_timeout = '5s';

DROP VIEW public.reviews;

ALTER TABLE public.danh_gia RENAME TO reviews;
ALTER TABLE public.reviews RENAME COLUMN khach_id TO customer_id;
ALTER TABLE public.reviews RENAME COLUMN san_pham_id TO product_id;
ALTER TABLE public.reviews RENAME COLUMN don_hang_id TO order_id;
ALTER TABLE public.reviews RENAME COLUMN so_sao TO rating;
ALTER TABLE public.reviews RENAME COLUMN noi_dung TO comment;
ALTER TABLE public.reviews RENAME COLUMN tao_luc TO created_at;
ALTER TABLE public.reviews RENAME CONSTRAINT danh_gia_don_hang_id_fkey TO reviews_order_id_fkey;
ALTER TABLE public.reviews RENAME CONSTRAINT danh_gia_khach_id_fkey TO reviews_customer_id_fkey;
ALTER TABLE public.reviews RENAME CONSTRAINT danh_gia_khach_id_san_pham_id_don_hang_id_key TO reviews_customer_id_product_id_order_id_key;
ALTER TABLE public.reviews RENAME CONSTRAINT danh_gia_pkey TO reviews_pkey;
ALTER TABLE public.reviews RENAME CONSTRAINT danh_gia_san_pham_id_fkey TO reviews_product_id_fkey;
ALTER TABLE public.reviews RENAME CONSTRAINT danh_gia_so_sao_check TO reviews_rating_check;
ALTER SEQUENCE public.danh_gia_id_seq RENAME TO reviews_id_seq;

ALTER INDEX public.danh_gia_san_pham_idx RENAME TO reviews_product_id_idx;

ALTER TABLE public.certificates
  RENAME CONSTRAINT chung_nhan_loai_so_hieu_key TO certificates_certificate_type_certificate_number_key;
ALTER TABLE public.production_batches
  RENAME CONSTRAINT lo_san_xuat_ma_truy_xuat_key TO production_batches_traceability_code_key;

COMMIT;
