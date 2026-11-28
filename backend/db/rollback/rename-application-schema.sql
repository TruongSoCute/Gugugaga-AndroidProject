-- Rollback for the schema rename. Uses the same rows and sequences.
BEGIN;
SET LOCAL lock_timeout = '5s';

DROP VIEW
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
  public.theo_doi_nha_cung_cap;

ALTER TABLE public.sourcing_regions RENAME COLUMN name TO ten;
ALTER TABLE public.sourcing_regions RENAME COLUMN description TO mo_ta;
ALTER TABLE public.sourcing_regions RENAME COLUMN latitude TO vi_do;
ALTER TABLE public.sourcing_regions RENAME COLUMN longitude TO kinh_do;
ALTER TABLE public.sourcing_regions RENAME CONSTRAINT sourcing_regions_longitude_check TO vung_nguyen_lieu_kinh_do_check;
ALTER TABLE public.sourcing_regions RENAME CONSTRAINT sourcing_regions_pkey TO vung_nguyen_lieu_pkey;
ALTER TABLE public.sourcing_regions RENAME CONSTRAINT sourcing_regions_name_key TO vung_nguyen_lieu_ten_key;
ALTER TABLE public.sourcing_regions RENAME CONSTRAINT sourcing_regions_latitude_check TO vung_nguyen_lieu_vi_do_check;
ALTER SEQUENCE public.sourcing_regions_id_seq RENAME TO vung_nguyen_lieu_id_seq;
ALTER TABLE public.sourcing_regions RENAME TO vung_nguyen_lieu;

ALTER TABLE public.users RENAME COLUMN password_hash TO mat_khau_hash;
ALTER TABLE public.users RENAME COLUMN full_name TO ho_ten;
ALTER TABLE public.users RENAME COLUMN phone_number TO so_dien_thoai;
ALTER TABLE public.users RENAME COLUMN role TO vai_tro;
ALTER TABLE public.users RENAME COLUMN is_active TO dang_hoat_dong;
ALTER TABLE public.users RENAME COLUMN created_at TO tao_luc;
ALTER TABLE public.users RENAME CONSTRAINT users_email_check TO nguoi_dung_email_check;
ALTER TABLE public.users RENAME CONSTRAINT users_email_key TO nguoi_dung_email_key;
ALTER TABLE public.users RENAME CONSTRAINT users_pkey TO nguoi_dung_pkey;
ALTER TABLE public.users RENAME CONSTRAINT users_role_check TO nguoi_dung_vai_tro_check;
ALTER SEQUENCE public.users_id_seq RENAME TO nguoi_dung_id_seq;
ALTER TABLE public.users RENAME TO nguoi_dung;

ALTER TABLE public.suppliers RENAME COLUMN name TO ten;
ALTER TABLE public.suppliers RENAME COLUMN representative_name TO nguoi_dai_dien;
ALTER TABLE public.suppliers RENAME COLUMN phone_number TO so_dien_thoai;
ALTER TABLE public.suppliers RENAME COLUMN address TO dia_chi;
ALTER TABLE public.suppliers RENAME COLUMN sourcing_region_id TO vung_id;
ALTER TABLE public.suppliers RENAME COLUMN facility_image_url TO anh_co_so_url;
ALTER TABLE public.suppliers RENAME COLUMN approval_status TO trang_thai_duyet;
ALTER TABLE public.suppliers RENAME COLUMN rejection_reason TO ly_do_tu_choi;
ALTER TABLE public.suppliers RENAME COLUMN reviewed_by_user_id TO nguoi_duyet_id;
ALTER TABLE public.suppliers RENAME COLUMN reviewed_at TO duyet_luc;
ALTER TABLE public.suppliers RENAME COLUMN created_by_user_id TO nguoi_tao_id;
ALTER TABLE public.suppliers RENAME COLUMN account_id TO tai_khoan_id;
ALTER TABLE public.suppliers RENAME COLUMN created_at TO tao_luc;
ALTER TABLE public.suppliers RENAME CONSTRAINT suppliers_reviewed_by_user_id_fkey TO nha_cung_cap_nguoi_duyet_id_fkey;
ALTER TABLE public.suppliers RENAME CONSTRAINT suppliers_created_by_user_id_fkey TO nha_cung_cap_nguoi_tao_id_fkey;
ALTER TABLE public.suppliers RENAME CONSTRAINT suppliers_pkey TO nha_cung_cap_pkey;
ALTER TABLE public.suppliers RENAME CONSTRAINT suppliers_account_id_fkey TO nha_cung_cap_tai_khoan_id_fkey;
ALTER TABLE public.suppliers RENAME CONSTRAINT suppliers_account_id_key TO nha_cung_cap_tai_khoan_id_key;
ALTER TABLE public.suppliers RENAME CONSTRAINT suppliers_approval_status_check TO nha_cung_cap_trang_thai_duyet_check;
ALTER TABLE public.suppliers RENAME CONSTRAINT suppliers_rejection_reason_check TO nha_cung_cap_tu_choi_co_ly_do;
ALTER TABLE public.suppliers RENAME CONSTRAINT suppliers_sourcing_region_id_fkey TO nha_cung_cap_vung_id_fkey;
ALTER SEQUENCE public.suppliers_id_seq RENAME TO nha_cung_cap_id_seq;
ALTER TABLE public.suppliers RENAME TO nha_cung_cap;

ALTER TABLE public.certificates RENAME COLUMN supplier_id TO nha_cung_cap_id;
ALTER TABLE public.certificates RENAME COLUMN certificate_type TO loai;
ALTER TABLE public.certificates RENAME COLUMN certificate_number TO so_hieu;
ALTER TABLE public.certificates RENAME COLUMN issued_on TO ngay_cap;
ALTER TABLE public.certificates RENAME COLUMN expires_on TO ngay_het_han;
ALTER TABLE public.certificates RENAME COLUMN image_url TO anh_url;
ALTER TABLE public.certificates RENAME CONSTRAINT certificates_check TO chung_nhan_check;
ALTER TABLE public.certificates RENAME CONSTRAINT certificates_supplier_id_fkey TO chung_nhan_nha_cung_cap_id_fkey;
ALTER TABLE public.certificates RENAME CONSTRAINT certificates_pkey TO chung_nhan_pkey;
ALTER SEQUENCE public.certificates_id_seq RENAME TO chung_nhan_id_seq;
ALTER TABLE public.certificates RENAME TO chung_nhan;

ALTER TABLE public.products RENAME COLUMN supplier_id TO nha_cung_cap_id;
ALTER TABLE public.products RENAME COLUMN name TO ten;
ALTER TABLE public.products RENAME COLUMN description TO mo_ta;
ALTER TABLE public.products RENAME COLUMN unit TO don_vi_tinh;
ALTER TABLE public.products RENAME COLUMN price_vnd TO gia;
ALTER TABLE public.products RENAME COLUMN ocop_rating TO hang_sao;
ALTER TABLE public.products RENAME COLUMN image_url TO anh_url;
ALTER TABLE public.products RENAME COLUMN approval_status TO trang_thai_duyet;
ALTER TABLE public.products RENAME COLUMN rejection_reason TO ly_do_tu_choi;
ALTER TABLE public.products RENAME COLUMN reviewed_by_user_id TO nguoi_duyet_id;
ALTER TABLE public.products RENAME COLUMN reviewed_at TO duyet_luc;
ALTER TABLE public.products RENAME COLUMN created_by_user_id TO nguoi_tao_id;
ALTER TABLE public.products RENAME COLUMN created_at TO tao_luc;
ALTER TABLE public.products RENAME CONSTRAINT products_approved_rating_check TO san_pham_da_duyet_co_hang_sao;
ALTER TABLE public.products RENAME CONSTRAINT products_price_vnd_check TO san_pham_gia_check;
ALTER TABLE public.products RENAME CONSTRAINT products_ocop_rating_check TO san_pham_hang_sao_check;
ALTER TABLE public.products RENAME CONSTRAINT products_reviewed_by_user_id_fkey TO san_pham_nguoi_duyet_id_fkey;
ALTER TABLE public.products RENAME CONSTRAINT products_created_by_user_id_fkey TO san_pham_nguoi_tao_id_fkey;
ALTER TABLE public.products RENAME CONSTRAINT products_supplier_id_fkey TO san_pham_nha_cung_cap_id_fkey;
ALTER TABLE public.products RENAME CONSTRAINT products_pkey TO san_pham_pkey;
ALTER TABLE public.products RENAME CONSTRAINT products_approval_status_check TO san_pham_trang_thai_duyet_check;
ALTER TABLE public.products RENAME CONSTRAINT products_rejection_reason_check TO san_pham_tu_choi_co_ly_do;
ALTER SEQUENCE public.products_id_seq RENAME TO san_pham_id_seq;
ALTER TABLE public.products RENAME TO san_pham;

ALTER TABLE public.production_batches RENAME COLUMN product_id TO san_pham_id;
ALTER TABLE public.production_batches RENAME COLUMN traceability_code TO ma_truy_xuat;
ALTER TABLE public.production_batches RENAME COLUMN produced_on TO ngay_san_xuat;
ALTER TABLE public.production_batches RENAME COLUMN expires_on TO han_su_dung;
ALTER TABLE public.production_batches RENAME COLUMN quantity TO so_luong;
ALTER TABLE public.production_batches RENAME COLUMN available_quantity TO so_luong_con;
ALTER TABLE public.production_batches RENAME COLUMN sourcing_region_id TO vung_nguyen_lieu_id;
ALTER TABLE public.production_batches RENAME COLUMN producer_name TO nguoi_san_xuat;
ALTER TABLE public.production_batches RENAME COLUMN site_image_url TO anh_hien_truong_url;
ALTER TABLE public.production_batches RENAME COLUMN notes TO ghi_chu;
ALTER TABLE public.production_batches RENAME COLUMN created_by_user_id TO nguoi_tao_id;
ALTER TABLE public.production_batches RENAME COLUMN created_at TO tao_luc;
ALTER TABLE public.production_batches RENAME CONSTRAINT production_batches_check TO lo_san_xuat_check;
ALTER TABLE public.production_batches RENAME CONSTRAINT production_batches_check1 TO lo_san_xuat_check1;
ALTER TABLE public.production_batches RENAME CONSTRAINT production_batches_id_product_id_key TO lo_san_xuat_id_san_pham_id_key;
ALTER TABLE public.production_batches RENAME CONSTRAINT production_batches_traceability_code_check TO lo_san_xuat_ma_truy_xuat_check;
ALTER TABLE public.production_batches RENAME CONSTRAINT production_batches_created_by_user_id_fkey TO lo_san_xuat_nguoi_tao_id_fkey;
ALTER TABLE public.production_batches RENAME CONSTRAINT production_batches_pkey TO lo_san_xuat_pkey;
ALTER TABLE public.production_batches RENAME CONSTRAINT production_batches_product_id_fkey TO lo_san_xuat_san_pham_id_fkey;
ALTER TABLE public.production_batches RENAME CONSTRAINT production_batches_quantity_check TO lo_san_xuat_so_luong_check;
ALTER TABLE public.production_batches RENAME CONSTRAINT production_batches_available_quantity_check TO lo_san_xuat_so_luong_con_check;
ALTER TABLE public.production_batches RENAME CONSTRAINT production_batches_sourcing_region_id_fkey TO lo_san_xuat_vung_nguyen_lieu_id_fkey;
ALTER SEQUENCE public.production_batches_id_seq RENAME TO lo_san_xuat_id_seq;
ALTER TABLE public.production_batches RENAME TO lo_san_xuat;

ALTER TABLE public.traceability_steps RENAME COLUMN batch_id TO lo_id;
ALTER TABLE public.traceability_steps RENAME COLUMN position TO thu_tu;
ALTER TABLE public.traceability_steps RENAME COLUMN name TO ten_buoc;
ALTER TABLE public.traceability_steps RENAME COLUMN description TO mo_ta;
ALTER TABLE public.traceability_steps RENAME COLUMN occurred_at TO thoi_diem;
ALTER TABLE public.traceability_steps RENAME COLUMN image_url TO anh_url;
ALTER TABLE public.traceability_steps RENAME CONSTRAINT traceability_steps_batch_id_fkey TO buoc_truy_xuat_lo_id_fkey;
ALTER TABLE public.traceability_steps RENAME CONSTRAINT traceability_steps_batch_id_position_key TO buoc_truy_xuat_lo_id_thu_tu_key;
ALTER TABLE public.traceability_steps RENAME CONSTRAINT traceability_steps_pkey TO buoc_truy_xuat_pkey;
ALTER TABLE public.traceability_steps RENAME CONSTRAINT traceability_steps_position_check TO buoc_truy_xuat_thu_tu_check;
ALTER SEQUENCE public.traceability_steps_id_seq RENAME TO buoc_truy_xuat_id_seq;
ALTER TABLE public.traceability_steps RENAME TO buoc_truy_xuat;

ALTER TABLE public.cart_items RENAME COLUMN user_id TO nguoi_dung_id;
ALTER TABLE public.cart_items RENAME COLUMN product_id TO san_pham_id;
ALTER TABLE public.cart_items RENAME COLUMN quantity TO so_luong;
ALTER TABLE public.cart_items RENAME COLUMN added_at TO them_luc;
ALTER TABLE public.cart_items RENAME CONSTRAINT cart_items_user_id_fkey TO gio_hang_nguoi_dung_id_fkey;
ALTER TABLE public.cart_items RENAME CONSTRAINT cart_items_pkey TO gio_hang_pkey;
ALTER TABLE public.cart_items RENAME CONSTRAINT cart_items_product_id_fkey TO gio_hang_san_pham_id_fkey;
ALTER TABLE public.cart_items RENAME CONSTRAINT cart_items_quantity_check TO gio_hang_so_luong_check;
ALTER TABLE public.cart_items RENAME TO gio_hang;

ALTER TABLE public.orders RENAME COLUMN customer_id TO khach_id;
ALTER TABLE public.orders RENAME COLUMN status TO trang_thai;
ALTER TABLE public.orders RENAME COLUMN delivery_method TO hinh_thuc_giao;
ALTER TABLE public.orders RENAME COLUMN delivery_fee_vnd TO phi_giao;
ALTER TABLE public.orders RENAME COLUMN subtotal_vnd TO tien_hang;
ALTER TABLE public.orders RENAME COLUMN total_vnd TO tong_tien;
ALTER TABLE public.orders RENAME COLUMN recipient_name TO ten_nguoi_nhan;
ALTER TABLE public.orders RENAME COLUMN recipient_phone TO sdt_nguoi_nhan;
ALTER TABLE public.orders RENAME COLUMN delivery_address TO dia_chi_giao;
ALTER TABLE public.orders RENAME COLUMN notes TO ghi_chu;
ALTER TABLE public.orders RENAME COLUMN created_at TO tao_luc;
ALTER TABLE public.orders RENAME COLUMN updated_at TO cap_nhat_luc;
ALTER TABLE public.orders RENAME CONSTRAINT orders_check TO don_hang_check;
ALTER TABLE public.orders RENAME CONSTRAINT orders_delivery_method_check TO don_hang_hinh_thuc_giao_check;
ALTER TABLE public.orders RENAME CONSTRAINT orders_customer_id_fkey TO don_hang_khach_id_fkey;
ALTER TABLE public.orders RENAME CONSTRAINT orders_delivery_fee_vnd_check TO don_hang_phi_giao_check;
ALTER TABLE public.orders RENAME CONSTRAINT orders_pkey TO don_hang_pkey;
ALTER TABLE public.orders RENAME CONSTRAINT orders_subtotal_vnd_check TO don_hang_tien_hang_check;
ALTER TABLE public.orders RENAME CONSTRAINT orders_total_vnd_check TO don_hang_tong_tien_check;
ALTER TABLE public.orders RENAME CONSTRAINT orders_status_check TO don_hang_trang_thai_check;
ALTER SEQUENCE public.orders_id_seq RENAME TO don_hang_id_seq;
ALTER TABLE public.orders RENAME TO don_hang;

ALTER TABLE public.order_items RENAME COLUMN order_id TO don_hang_id;
ALTER TABLE public.order_items RENAME COLUMN product_id TO san_pham_id;
ALTER TABLE public.order_items RENAME COLUMN batch_id TO lo_id;
ALTER TABLE public.order_items RENAME COLUMN quantity TO so_luong;
ALTER TABLE public.order_items RENAME COLUMN unit_price_vnd TO don_gia;
ALTER TABLE public.order_items RENAME CONSTRAINT order_items_unit_price_vnd_check TO chi_tiet_don_don_gia_check;
ALTER TABLE public.order_items RENAME CONSTRAINT order_items_order_id_fkey TO chi_tiet_don_don_hang_id_fkey;
ALTER TABLE public.order_items RENAME CONSTRAINT order_items_order_id_batch_id_key TO chi_tiet_don_don_hang_id_lo_id_key;
ALTER TABLE public.order_items RENAME CONSTRAINT order_items_batch_id_product_id_fkey TO chi_tiet_don_lo_id_san_pham_id_fkey;
ALTER TABLE public.order_items RENAME CONSTRAINT order_items_pkey TO chi_tiet_don_pkey;
ALTER TABLE public.order_items RENAME CONSTRAINT order_items_quantity_check TO chi_tiet_don_so_luong_check;
ALTER SEQUENCE public.order_items_id_seq RENAME TO chi_tiet_don_id_seq;
ALTER TABLE public.order_items RENAME TO chi_tiet_don;

ALTER TABLE public.order_status_history RENAME COLUMN order_id TO don_hang_id;
ALTER TABLE public.order_status_history RENAME COLUMN status TO trang_thai;
ALTER TABLE public.order_status_history RENAME COLUMN notes TO ghi_chu;
ALTER TABLE public.order_status_history RENAME COLUMN changed_by_user_id TO nguoi_thuc_hien_id;
ALTER TABLE public.order_status_history RENAME COLUMN changed_at TO thoi_diem;
ALTER TABLE public.order_status_history RENAME CONSTRAINT order_status_history_order_id_fkey TO lich_su_trang_thai_don_don_hang_id_fkey;
ALTER TABLE public.order_status_history RENAME CONSTRAINT order_status_history_changed_by_user_id_fkey TO lich_su_trang_thai_don_nguoi_thuc_hien_id_fkey;
ALTER TABLE public.order_status_history RENAME CONSTRAINT order_status_history_pkey TO lich_su_trang_thai_don_pkey;
ALTER SEQUENCE public.order_status_history_id_seq RENAME TO lich_su_trang_thai_don_id_seq;
ALTER TABLE public.order_status_history RENAME TO lich_su_trang_thai_don;

ALTER TABLE public.review_images RENAME COLUMN review_id TO danh_gia_id;
ALTER TABLE public.review_images RENAME COLUMN image_url TO anh_url;
ALTER TABLE public.review_images RENAME CONSTRAINT review_images_review_id_fkey TO anh_danh_gia_danh_gia_id_fkey;
ALTER TABLE public.review_images RENAME CONSTRAINT review_images_pkey TO anh_danh_gia_pkey;
ALTER SEQUENCE public.review_images_id_seq RENAME TO anh_danh_gia_id_seq;
ALTER TABLE public.review_images RENAME TO anh_danh_gia;

ALTER TABLE public.issue_reports RENAME COLUMN reporter_id TO nguoi_bao_id;
ALTER TABLE public.issue_reports RENAME COLUMN product_id TO san_pham_id;
ALTER TABLE public.issue_reports RENAME COLUMN batch_id TO lo_id;
ALTER TABLE public.issue_reports RENAME COLUMN report_type TO loai;
ALTER TABLE public.issue_reports RENAME COLUMN description TO noi_dung;
ALTER TABLE public.issue_reports RENAME COLUMN image_url TO anh_url;
ALTER TABLE public.issue_reports RENAME COLUMN status TO trang_thai;
ALTER TABLE public.issue_reports RENAME COLUMN resolution TO ket_qua_xu_ly;
ALTER TABLE public.issue_reports RENAME COLUMN handled_by_user_id TO nguoi_xu_ly_id;
ALTER TABLE public.issue_reports RENAME COLUMN handled_at TO xu_ly_luc;
ALTER TABLE public.issue_reports RENAME COLUMN created_at TO tao_luc;
ALTER TABLE public.issue_reports RENAME CONSTRAINT issue_reports_batch_id_product_id_fkey TO bao_cao_vi_pham_lo_id_san_pham_id_fkey;
ALTER TABLE public.issue_reports RENAME CONSTRAINT issue_reports_report_type_check TO bao_cao_vi_pham_loai_check;
ALTER TABLE public.issue_reports RENAME CONSTRAINT issue_reports_reporter_id_fkey TO bao_cao_vi_pham_nguoi_bao_id_fkey;
ALTER TABLE public.issue_reports RENAME CONSTRAINT issue_reports_handled_by_user_id_fkey TO bao_cao_vi_pham_nguoi_xu_ly_id_fkey;
ALTER TABLE public.issue_reports RENAME CONSTRAINT issue_reports_pkey TO bao_cao_vi_pham_pkey;
ALTER TABLE public.issue_reports RENAME CONSTRAINT issue_reports_product_id_fkey TO bao_cao_vi_pham_san_pham_id_fkey;
ALTER TABLE public.issue_reports RENAME CONSTRAINT issue_reports_status_check TO bao_cao_vi_pham_trang_thai_check;
ALTER SEQUENCE public.issue_reports_id_seq RENAME TO bao_cao_vi_pham_id_seq;
ALTER TABLE public.issue_reports RENAME TO bao_cao_vi_pham;

ALTER TABLE public.product_favorites RENAME COLUMN user_id TO nguoi_dung_id;
ALTER TABLE public.product_favorites RENAME COLUMN product_id TO san_pham_id;
ALTER TABLE public.product_favorites RENAME COLUMN created_at TO tao_luc;
ALTER TABLE public.product_favorites RENAME CONSTRAINT product_favorites_user_id_fkey TO yeu_thich_nguoi_dung_id_fkey;
ALTER TABLE public.product_favorites RENAME CONSTRAINT product_favorites_pkey TO yeu_thich_pkey;
ALTER TABLE public.product_favorites RENAME CONSTRAINT product_favorites_product_id_fkey TO yeu_thich_san_pham_id_fkey;
ALTER TABLE public.product_favorites RENAME TO yeu_thich;

ALTER TABLE public.supplier_follows RENAME COLUMN user_id TO nguoi_dung_id;
ALTER TABLE public.supplier_follows RENAME COLUMN supplier_id TO nha_cung_cap_id;
ALTER TABLE public.supplier_follows RENAME COLUMN created_at TO tao_luc;
ALTER TABLE public.supplier_follows RENAME CONSTRAINT supplier_follows_user_id_fkey TO theo_doi_nha_cung_cap_nguoi_dung_id_fkey;
ALTER TABLE public.supplier_follows RENAME CONSTRAINT supplier_follows_supplier_id_fkey TO theo_doi_nha_cung_cap_nha_cung_cap_id_fkey;
ALTER TABLE public.supplier_follows RENAME CONSTRAINT supplier_follows_pkey TO theo_doi_nha_cung_cap_pkey;
ALTER TABLE public.supplier_follows RENAME TO theo_doi_nha_cung_cap;

ALTER INDEX public.suppliers_sourcing_region_id_idx RENAME TO nha_cung_cap_vung_idx;
ALTER INDEX public.certificates_supplier_id_idx RENAME TO chung_nhan_ncc_idx;
ALTER INDEX public.products_supplier_id_idx RENAME TO san_pham_ncc_idx;
ALTER INDEX public.products_approval_status_ocop_rating_idx RENAME TO san_pham_trang_thai_idx;
ALTER INDEX public.production_batches_product_id_idx RENAME TO lo_san_xuat_san_pham_idx;
ALTER INDEX public.production_batches_sourcing_region_id_idx RENAME TO lo_san_xuat_vung_idx;
ALTER INDEX public.orders_customer_id_idx RENAME TO don_hang_khach_idx;
ALTER INDEX public.orders_status_idx RENAME TO don_hang_trang_thai_idx;
ALTER INDEX public.order_items_batch_id_idx RENAME TO chi_tiet_don_lo_idx;
ALTER INDEX public.order_items_product_id_idx RENAME TO chi_tiet_don_san_pham_idx;
ALTER INDEX public.order_status_history_order_id_idx RENAME TO lich_su_don_idx;
ALTER INDEX public.issue_reports_status_idx RENAME TO bao_cao_trang_thai_idx;

COMMIT;
