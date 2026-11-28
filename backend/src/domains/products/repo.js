'use strict';

const { withApiColumns, camel, escapeLike } = require('../../utils/sql');

// Sản phẩm được công bố khi chính nó và nhà cung cấp đều đã được duyệt.
const CONG_BO = "sp.approval_status = 'DA_DUYET' AND ncc.approval_status = 'DA_DUYET'";

const COT = `sp.id, sp.name, sp.description, sp.unit, sp.price_vnd, sp.ocop_rating, sp.image_url,
  sp.supplier_id, ncc.name AS ten_nha_cung_cap, ncc.sourcing_region_id, v.name AS ten_vung,
  COALESCE(dg.so_danh_gia, 0) AS so_danh_gia, dg.diem_trung_binh`;
const COT_QUAN_TRI_DS = ', sp.approval_status, ncc.approval_status AS trang_thai_nha_cung_cap, sp.created_at';
const COT_QUAN_TRI_CT = `, sp.approval_status, sp.rejection_reason, sp.reviewed_at, sp.created_at,
  ncc.approval_status AS trang_thai_nha_cung_cap`;

const FROM = `FROM products sp
  JOIN suppliers ncc ON ncc.id = sp.supplier_id
  JOIN sourcing_regions v ON v.id = ncc.sourcing_region_id
  LEFT JOIN (
    SELECT product_id, count(*) AS so_danh_gia, round(avg(rating), 1) AS diem_trung_binh
    FROM reviews GROUP BY product_id
  ) dg ON dg.product_id = sp.id`;

// Ghép điều kiện WHERE từ bộ lọc. Giá trị luôn đi qua tham số $n, không ghép vào chuỗi SQL.
function dieuKien(loc, quanTri) {
  const where = [quanTri ? 'TRUE' : CONG_BO];
  const params = [];
  const add = (sql, value) => {
    params.push(value);
    where.push(sql.replace('?', `$${params.length}`));
  };
  if (loc.vung) add('ncc.sourcing_region_id = ?', loc.vung);
  if (loc.hangSao) add('sp.ocop_rating = ?', loc.hangSao);
  if (loc.nhaCungCapId) add('sp.supplier_id = ?', loc.nhaCungCapId);
  if (loc.tuKhoa) add("sp.name ILIKE ? ESCAPE '\\'", `%${escapeLike(loc.tuKhoa)}%`);
  if (loc.trangThai) add('sp.approval_status = ?', loc.trangThai);
  return { where: where.join(' AND '), params };
}

// Trả dòng thô có cột "tong" để service đóng gói phân trang.
async function danhSach(q, loc, { quanTri, limit, offset }) {
  const { where, params } = dieuKien(loc, quanTri);
  const order = quanTri ? "(sp.approval_status = 'CHO_DUYET') DESC, sp.created_at DESC" : 'sp.ocop_rating DESC, sp.name';
  const { rows } = withApiColumns(await q.query(
    `SELECT ${COT}${quanTri ? COT_QUAN_TRI_DS : ''}, count(*) OVER () AS tong
     ${FROM}
     WHERE ${where}
     ORDER BY ${order}, sp.id
     LIMIT $${params.length + 1} OFFSET $${params.length + 2}`,
    [...params, limit, offset],
  ));
  return rows;
}

async function timTheoId(q, id, { quanTri }) {
  const { rows } = withApiColumns(await q.query(
    `SELECT ${COT}${quanTri ? COT_QUAN_TRI_CT : ''}, ncc.address AS dia_chi_nha_cung_cap, ncc.facility_image_url
     ${FROM}
     WHERE sp.id = $1 AND ${quanTri ? 'TRUE' : CONG_BO}`,
    [id],
  ));
  return camel(rows[0]);
}

// Đánh giá công khai chỉ có tên người đánh giá, không có email/số điện thoại.
async function danhGiaGanDay(q, sanPhamId, limit = 10) {
  const { rows } = withApiColumns(await q.query(
    `SELECT dg.id, dg.rating, dg.comment, dg.created_at, nd.full_name AS ten_nguoi_danh_gia,
            COALESCE(array_agg(a.image_url ORDER BY a.id) FILTER (WHERE a.id IS NOT NULL), '{}') AS anh
     FROM reviews dg
     JOIN users nd ON nd.id = dg.customer_id
     LEFT JOIN review_images a ON a.review_id = dg.id
     WHERE dg.product_id = $1
     GROUP BY dg.id, dg.rating, dg.comment, dg.created_at, nd.full_name
     ORDER BY dg.created_at DESC
     LIMIT $2`,
    [sanPhamId, limit],
  ));
  return rows.map(camel);
}

async function trangThaiNhaCungCap(q, nhaCungCapId) {
  const { rows } = withApiColumns(await q.query('SELECT approval_status FROM suppliers WHERE id = $1', [nhaCungCapId]));
  return rows[0]?.trang_thai_duyet ?? null;
}

async function them(q, d, nguoiTaoId) {
  const { rows } = withApiColumns(await q.query(
    `INSERT INTO products (supplier_id, name, description, unit, price_vnd, image_url, created_by_user_id)
     VALUES ($1, $2, $3, COALESCE($4, 'gói'), $5, $6, $7) RETURNING id`,
    [d.nhaCungCapId, d.ten, d.moTa || null, d.donViTinh || null, d.gia, d.anhUrl || null, nguoiTaoId],
  ));
  return rows[0].id;
}

// Khóa dòng sản phẩm để hai người duyệt cùng lúc không ghi đè nhau.
async function khoaDeDuyet(q, id) {
  const { rows } = withApiColumns(await q.query(
    `SELECT sp.approval_status, sp.ocop_rating, ncc.approval_status AS trang_thai_nha_cung_cap
     FROM products sp JOIN suppliers ncc ON ncc.id = sp.supplier_id
     WHERE sp.id = $1 FOR UPDATE OF sp`,
    [id],
  ));
  return camel(rows[0]);
}

async function capNhatDuyet(q, id, { trangThai, hangSao, lyDoTuChoi, nguoiDuyetId }) {
  await q.query(
    `UPDATE products
     SET approval_status = $2::varchar,
         ocop_rating = CASE WHEN $2::varchar = 'DA_DUYET' THEN $3::smallint ELSE ocop_rating END,
         rejection_reason = $4, reviewed_by_user_id = $5, reviewed_at = now()
     WHERE id = $1`,
    [id, trangThai, hangSao ?? null, lyDoTuChoi, nguoiDuyetId],
  );
}

// Sản phẩm của một nhà cung cấp, mọi trạng thái (nhà cung cấp xem trên app Client).
const COT_CUA_TOI = `sp.id, sp.name, sp.description, sp.unit, sp.price_vnd, sp.ocop_rating, sp.image_url,
  sp.approval_status, sp.rejection_reason, sp.reviewed_at, sp.created_at,
  (SELECT count(*) FROM production_batches lo WHERE lo.product_id = sp.id) AS so_lo,
  COALESCE((SELECT sum(lo.available_quantity) FROM production_batches lo WHERE lo.product_id = sp.id), 0) AS ton_kho`;

async function dsCuaNhaCungCap(q, nhaCungCapId) {
  const { rows } = withApiColumns(await q.query(
    `SELECT ${COT_CUA_TOI} FROM products sp WHERE sp.supplier_id = $1
     ORDER BY (sp.approval_status = 'CHO_DUYET') DESC, sp.created_at DESC, sp.id DESC`,
    [nhaCungCapId],
  ));
  return rows.map(camel);
}

async function timCuaNhaCungCap(q, id, nhaCungCapId, { khoa = false } = {}) {
  const { rows } = withApiColumns(await q.query(
    `SELECT ${COT_CUA_TOI} FROM products sp WHERE sp.id = $1 AND sp.supplier_id = $2${khoa ? ' FOR UPDATE' : ''}`,
    [id, nhaCungCapId],
  ));
  return camel(rows[0]);
}

// Nhà cung cấp sửa sản phẩm: đưa về CHO_DUYET, xóa hạng sao và kết quả duyệt cũ để quản trị duyệt lại.
async function capNhatChoDuyetLai(q, id, d) {
  await q.query(
    `UPDATE products
     SET name = $2, description = $3, unit = COALESCE($4, unit), price_vnd = $5, image_url = $6,
         approval_status = 'CHO_DUYET', ocop_rating = NULL, rejection_reason = NULL,
         reviewed_by_user_id = NULL, reviewed_at = NULL
     WHERE id = $1`,
    [id, d.ten, d.moTa || null, d.donViTinh || null, d.gia, d.anhUrl || null],
  );
}

module.exports = {
  danhSach, timTheoId, danhGiaGanDay, trangThaiNhaCungCap, them, khoaDeDuyet, capNhatDuyet,
  dsCuaNhaCungCap, timCuaNhaCungCap, capNhatChoDuyetLai,
};
