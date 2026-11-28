'use strict';

const { withApiColumns, camel } = require('../../utils/sql');

// Các dòng chi tiết đơn được tính doanh số, đã lọc theo trạng thái, khoảng ngày và vùng của lô.
// Doanh số = số lượng x đơn giá lúc đặt; không tính phí giao.
const DONG_TINH = `
  SELECT c.quantity, c.quantity * c.unit_price_vnd AS thanh_tien, c.order_id,
         lo.sourcing_region_id, sp.ocop_rating, sp.supplier_id
  FROM order_items c
  JOIN orders dh ON dh.id = c.order_id
  JOIN production_batches lo ON lo.id = c.batch_id
  JOIN products sp ON sp.id = c.product_id
  WHERE dh.status = ANY($1::varchar[])
    AND ($2::date IS NULL OR (dh.created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date >= $2)
    AND ($3::date IS NULL OR (dh.created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date <= $3)
    AND ($4::int IS NULL OR lo.sourcing_region_id = $4)`;

const thamSo = (loc, trangThai) => [trangThai, loc.tu ?? null, loc.den ?? null, loc.vung ?? null];

async function tong(q, loc, trangThai) {
  const { rows } = withApiColumns(await q.query(
    `SELECT COALESCE(sum(thanh_tien), 0) AS doanh_so, COALESCE(sum(quantity), 0) AS so_luong,
            count(DISTINCT order_id) AS so_don
     FROM (${DONG_TINH}) d`,
    thamSo(loc, trangThai),
  ));
  return camel(rows[0]);
}

// Mọi vùng đều có mặt, kể cả vùng chưa có doanh số (để biểu đồ đủ cột).
async function theoVung(q, loc, trangThai) {
  const { rows } = withApiColumns(await q.query(
    `SELECT v.id AS vung_id, v.name AS ten_vung,
            COALESCE(sum(d.thanh_tien), 0) AS doanh_so, COALESCE(sum(d.quantity), 0) AS so_luong
     FROM sourcing_regions v LEFT JOIN (${DONG_TINH}) d ON d.sourcing_region_id = v.id
     WHERE ($4::int IS NULL OR v.id = $4)
     GROUP BY v.id, v.name ORDER BY doanh_so DESC, v.id`,
    thamSo(loc, trangThai),
  ));
  return rows.map(camel);
}

async function theoHangSao(q, loc, trangThai) {
  const { rows } = withApiColumns(await q.query(
    `SELECT h.ocop_rating, COALESCE(sum(d.thanh_tien), 0) AS doanh_so, COALESCE(sum(d.quantity), 0) AS so_luong
     FROM generate_series(3, 5) AS h (ocop_rating) LEFT JOIN (${DONG_TINH}) d ON d.ocop_rating = h.ocop_rating
     GROUP BY h.ocop_rating ORDER BY h.ocop_rating`,
    thamSo(loc, trangThai),
  ));
  return rows.map(camel);
}

async function nhaCungCapBanChay(q, loc, trangThai, limit) {
  const { rows } = withApiColumns(await q.query(
    `SELECT ncc.id, ncc.name, v.name AS ten_vung,
            sum(d.thanh_tien) AS doanh_so, sum(d.quantity) AS so_luong, count(DISTINCT d.order_id) AS so_don
     FROM (${DONG_TINH}) d
     JOIN suppliers ncc ON ncc.id = d.supplier_id
     JOIN sourcing_regions v ON v.id = ncc.sourcing_region_id
     GROUP BY ncc.id, ncc.name, v.name
     ORDER BY doanh_so DESC, ncc.id
     LIMIT $5`,
    [...thamSo(loc, trangThai), limit],
  ));
  return rows.map(camel);
}

module.exports = { tong, theoVung, theoHangSao, nhaCungCapBanChay };
