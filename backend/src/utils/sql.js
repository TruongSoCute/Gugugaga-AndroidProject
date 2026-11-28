'use strict';

// Tiện ích thuần (không trạng thái, không I/O) dùng chung cho tầng repo/service/routes.

// Keep the v1 field names at the repository boundary. Use explicit SQL aliases
// where a column has different v1 names in different queries.
const API_COLUMNS = Object.freeze({
  account_id: 'tai_khoan_id',
  added_at: 'them_luc',
  address: 'dia_chi',
  approval_status: 'trang_thai_duyet',
  available_quantity: 'so_luong_con',
  batch_id: 'lo_id',
  certificate_number: 'so_hieu',
  certificate_type: 'loai',
  changed_at: 'thoi_diem',
  changed_by_user_id: 'nguoi_thuc_hien_id',
  comment: 'noi_dung',
  created_at: 'tao_luc',
  created_by_user_id: 'nguoi_tao_id',
  customer_id: 'khach_id',
  delivery_address: 'dia_chi_giao',
  delivery_fee_vnd: 'phi_giao',
  delivery_method: 'hinh_thuc_giao',
  description: 'mo_ta',
  expires_on: 'han_su_dung',
  facility_image_url: 'anh_co_so_url',
  full_name: 'ho_ten',
  handled_at: 'xu_ly_luc',
  handled_by_user_id: 'nguoi_xu_ly_id',
  image_url: 'anh_url',
  is_active: 'dang_hoat_dong',
  issued_on: 'ngay_cap',
  latitude: 'vi_do',
  longitude: 'kinh_do',
  name: 'ten',
  notes: 'ghi_chu',
  occurred_at: 'thoi_diem',
  ocop_rating: 'hang_sao',
  order_id: 'don_hang_id',
  password_hash: 'mat_khau_hash',
  phone_number: 'so_dien_thoai',
  position: 'thu_tu',
  price_vnd: 'gia',
  produced_on: 'ngay_san_xuat',
  producer_name: 'nguoi_san_xuat',
  product_id: 'san_pham_id',
  quantity: 'so_luong',
  rating: 'so_sao',
  recipient_name: 'ten_nguoi_nhan',
  recipient_phone: 'sdt_nguoi_nhan',
  rejection_reason: 'ly_do_tu_choi',
  report_type: 'loai',
  reporter_id: 'nguoi_bao_id',
  representative_name: 'nguoi_dai_dien',
  resolution: 'ket_qua_xu_ly',
  review_id: 'danh_gia_id',
  reviewed_at: 'duyet_luc',
  reviewed_by_user_id: 'nguoi_duyet_id',
  role: 'vai_tro',
  site_image_url: 'anh_hien_truong_url',
  sourcing_region_id: 'vung_id',
  status: 'trang_thai',
  subtotal_vnd: 'tien_hang',
  supplier_id: 'nha_cung_cap_id',
  total_vnd: 'tong_tien',
  traceability_code: 'ma_truy_xuat',
  unit: 'don_vi_tinh',
  unit_price_vnd: 'don_gia',
  updated_at: 'cap_nhat_luc',
  user_id: 'nguoi_dung_id',
});

function withApiColumns(result) {
  return {
    ...result,
    rows: result.rows.map((row) => Object.fromEntries(
      Object.entries(row).map(([column, value]) => [Object.hasOwn(API_COLUMNS, column) ? API_COLUMNS[column] : column, value]),
    )),
  };
}

// Đổi khóa snake_case của dòng SQL sang camelCase cho JSON trả về app.
function camel(row) {
  if (!row) return row;
  const out = {};
  for (const [k, v] of Object.entries(row)) {
    out[k.replace(/_([a-z0-9])/g, (_, c) => c.toUpperCase())] = v;
  }
  return out;
}

// Thoát ký tự đặc biệt của LIKE để từ khóa người dùng không thành mẫu tìm kiếm.
function escapeLike(s) {
  return s.replace(/[\\%_]/g, (c) => `\\${c}`);
}

// Đọc trang/kichThuoc từ query string; mặc định 1/20, tối đa 100 dòng mỗi trang.
function phanTrang(query) {
  const trang = Math.max(1, Number.parseInt(query.trang, 10) || 1);
  const kichThuoc = Math.min(100, Math.max(1, Number.parseInt(query.kichThuoc, 10) || 20));
  return { trang, kichThuoc, offset: (trang - 1) * kichThuoc };
}

// Gói kết quả danh sách có cột "tong" (count(*) OVER ()) thành { duLieu, phanTrang }.
function ketQuaPhanTrang(rows, p) {
  return {
    duLieu: rows.map(({ tong, ...r }) => camel(r)),
    phanTrang: { trang: p.trang, kichThuoc: p.kichThuoc, tong: rows[0]?.tong ?? 0 },
  };
}

// Biểu thức SQL: ngày hiện tại theo giờ Việt Nam (CSDL Supabase chạy theo UTC).
const HOM_NAY_SQL = "(now() AT TIME ZONE 'Asia/Ho_Chi_Minh')::date";

module.exports = { withApiColumns, camel, escapeLike, phanTrang, ketQuaPhanTrang, HOM_NAY_SQL };
