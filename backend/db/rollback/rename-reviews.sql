-- Restore the transition schema before rolling Render back to the older backend.
BEGIN;
SET LOCAL lock_timeout = '5s';

ALTER TABLE public.reviews RENAME COLUMN customer_id TO khach_id;
ALTER TABLE public.reviews RENAME COLUMN product_id TO san_pham_id;
ALTER TABLE public.reviews RENAME COLUMN order_id TO don_hang_id;
ALTER TABLE public.reviews RENAME COLUMN rating TO so_sao;
ALTER TABLE public.reviews RENAME COLUMN comment TO noi_dung;
ALTER TABLE public.reviews RENAME COLUMN created_at TO tao_luc;
ALTER TABLE public.reviews RENAME CONSTRAINT reviews_order_id_fkey TO danh_gia_don_hang_id_fkey;
ALTER TABLE public.reviews RENAME CONSTRAINT reviews_customer_id_fkey TO danh_gia_khach_id_fkey;
ALTER TABLE public.reviews RENAME CONSTRAINT reviews_customer_id_product_id_order_id_key TO danh_gia_khach_id_san_pham_id_don_hang_id_key;
ALTER TABLE public.reviews RENAME CONSTRAINT reviews_pkey TO danh_gia_pkey;
ALTER TABLE public.reviews RENAME CONSTRAINT reviews_product_id_fkey TO danh_gia_san_pham_id_fkey;
ALTER TABLE public.reviews RENAME CONSTRAINT reviews_rating_check TO danh_gia_so_sao_check;
ALTER SEQUENCE public.reviews_id_seq RENAME TO danh_gia_id_seq;
ALTER TABLE public.reviews RENAME TO danh_gia;

ALTER INDEX public.reviews_product_id_idx RENAME TO danh_gia_san_pham_idx;

ALTER TABLE public.certificates
  RENAME CONSTRAINT certificates_certificate_type_certificate_number_key TO chung_nhan_loai_so_hieu_key;
ALTER TABLE public.production_batches
  RENAME CONSTRAINT production_batches_traceability_code_key TO lo_san_xuat_ma_truy_xuat_key;

CREATE VIEW public.reviews WITH (security_invoker = true) AS
SELECT id, khach_id AS customer_id, san_pham_id AS product_id, don_hang_id AS order_id,
       so_sao AS rating, noi_dung AS comment, tao_luc AS created_at
FROM public.danh_gia;

REVOKE ALL ON TABLE public.reviews FROM PUBLIC;
DO $$
DECLARE client_role text;
BEGIN
  FOR client_role IN
    SELECT rolname FROM pg_roles WHERE rolname IN ('anon', 'authenticated', 'service_role')
  LOOP
    EXECUTE format('REVOKE ALL ON TABLE public.reviews FROM %I', client_role);
  END LOOP;
END $$;

COMMIT;
