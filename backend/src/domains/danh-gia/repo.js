'use strict';

const { camel } = require('../../utils/sql');

// Đơn của khách có chứa sản phẩm này không, và trạng thái đơn.
async function donChuaSanPham(q, { donHangId, khachId, sanPhamId }) {
  const { rows } = await q.query(
    `SELECT dh.trang_thai,
            EXISTS (SELECT 1 FROM chi_tiet_don c WHERE c.don_hang_id = dh.id AND c.san_pham_id = $3) AS co_san_pham
     FROM don_hang dh WHERE dh.id = $1 AND dh.khach_id = $2`,
    [donHangId, khachId, sanPhamId],
  );
  return camel(rows[0]);
}

async function themDanhGia(q, d) {
  const { rows } = await q.query(
    `INSERT INTO danh_gia (khach_id, san_pham_id, don_hang_id, so_sao, noi_dung)
     VALUES ($1, $2, $3, $4, $5) RETURNING id`,
    [d.khachId, d.sanPhamId, d.donHangId, d.soSao, d.noiDung || null],
  );
  return rows[0].id;
}

async function themAnh(q, danhGiaId, anhUrl) {
  await q.query('INSERT INTO anh_danh_gia (danh_gia_id, anh_url) VALUES ($1, $2)', [danhGiaId, anhUrl]);
}

// Đánh giá công khai chỉ có tên người đánh giá, không có email hay số điện thoại.
const COT = `dg.id, dg.san_pham_id, dg.don_hang_id, dg.so_sao, dg.noi_dung, dg.tao_luc,
  nd.ho_ten AS ten_nguoi_danh_gia,
  COALESCE((SELECT array_agg(a.anh_url ORDER BY a.id) FROM anh_danh_gia a WHERE a.danh_gia_id = dg.id), '{}') AS anh`;

async function timTheoId(q, id) {
  const { rows } = await q.query(
    `SELECT ${COT} FROM danh_gia dg JOIN nguoi_dung nd ON nd.id = dg.khach_id WHERE dg.id = $1`,
    [id],
  );
  return camel(rows[0]);
}

async function dsTheoSanPham(q, sanPhamId, { limit, offset }) {
  const { rows } = await q.query(
    `SELECT ${COT}, count(*) OVER () AS tong
     FROM danh_gia dg JOIN nguoi_dung nd ON nd.id = dg.khach_id
     WHERE dg.san_pham_id = $1
     ORDER BY dg.tao_luc DESC, dg.id DESC
     LIMIT $2 OFFSET $3`,
    [sanPhamId, limit, offset],
  );
  return rows;
}

async function tongHop(q, sanPhamId) {
  const { rows } = await q.query(
    `SELECT count(*) AS so_danh_gia, round(avg(so_sao), 1) AS diem_trung_binh
     FROM danh_gia WHERE san_pham_id = $1`,
    [sanPhamId],
  );
  return camel(rows[0]);
}

module.exports = { donChuaSanPham, themDanhGia, themAnh, timTheoId, dsTheoSanPham, tongHop };
