'use strict';

const { withApiColumns, camel } = require('../../utils/sql');

// Đơn của khách có chứa sản phẩm này không, và trạng thái đơn.
async function donChuaSanPham(q, { donHangId, khachId, sanPhamId }) {
  const { rows } = withApiColumns(await q.query(
    `SELECT dh.status,
            EXISTS (SELECT 1 FROM order_items c WHERE c.order_id = dh.id AND c.product_id = $3) AS co_san_pham
     FROM orders dh WHERE dh.id = $1 AND dh.customer_id = $2`,
    [donHangId, khachId, sanPhamId],
  ));
  return camel(rows[0]);
}

async function themDanhGia(q, d) {
  const { rows } = withApiColumns(await q.query(
    `INSERT INTO reviews (customer_id, product_id, order_id, rating, comment)
     VALUES ($1, $2, $3, $4, $5) RETURNING id`,
    [d.khachId, d.sanPhamId, d.donHangId, d.soSao, d.noiDung || null],
  ));
  return rows[0].id;
}

async function themAnh(q, danhGiaId, anhUrl) {
  await q.query('INSERT INTO review_images (review_id, image_url) VALUES ($1, $2)', [danhGiaId, anhUrl]);
}

// Đánh giá công khai chỉ có tên người đánh giá, không có email hay số điện thoại.
const COT = `dg.id, dg.product_id, dg.order_id, dg.rating, dg.comment, dg.created_at,
  nd.full_name AS ten_nguoi_danh_gia,
  COALESCE((SELECT array_agg(a.image_url ORDER BY a.id) FROM review_images a WHERE a.review_id = dg.id), '{}') AS anh`;

async function timTheoId(q, id) {
  const { rows } = withApiColumns(await q.query(
    `SELECT ${COT} FROM reviews dg JOIN users nd ON nd.id = dg.customer_id WHERE dg.id = $1`,
    [id],
  ));
  return camel(rows[0]);
}

async function dsTheoSanPham(q, sanPhamId, { limit, offset }) {
  const { rows } = withApiColumns(await q.query(
    `SELECT ${COT}, count(*) OVER () AS tong
     FROM reviews dg JOIN users nd ON nd.id = dg.customer_id
     WHERE dg.product_id = $1
     ORDER BY dg.created_at DESC, dg.id DESC
     LIMIT $2 OFFSET $3`,
    [sanPhamId, limit, offset],
  ));
  return rows;
}

async function tongHop(q, sanPhamId) {
  const { rows } = withApiColumns(await q.query(
    `SELECT count(*) AS so_danh_gia, round(avg(rating), 1) AS diem_trung_binh
     FROM reviews WHERE product_id = $1`,
    [sanPhamId],
  ));
  return camel(rows[0]);
}

module.exports = { donChuaSanPham, themDanhGia, themAnh, timTheoId, dsTheoSanPham, tongHop };
