'use strict';

const { camel } = require('../../utils/sql');

// Các dòng chi tiết đơn được tính doanh số, đã lọc theo trạng thái, khoảng ngày và vùng của lô.
// Doanh số = số lượng x đơn giá lúc đặt; không tính phí giao.
const DONG_TINH = `
  SELECT c.so_luong, c.so_luong * c.don_gia AS thanh_tien, c.don_hang_id,
         lo.vung_nguyen_lieu_id AS vung_id, sp.hang_sao, sp.nha_cung_cap_id
  FROM chi_tiet_don c
  JOIN don_hang dh ON dh.id = c.don_hang_id
  JOIN lo_san_xuat lo ON lo.id = c.lo_id
  JOIN san_pham sp ON sp.id = c.san_pham_id
  WHERE dh.trang_thai = ANY($1::varchar[])
    AND ($2::date IS NULL OR (dh.tao_luc AT TIME ZONE 'Asia/Ho_Chi_Minh')::date >= $2)
    AND ($3::date IS NULL OR (dh.tao_luc AT TIME ZONE 'Asia/Ho_Chi_Minh')::date <= $3)
    AND ($4::int IS NULL OR lo.vung_nguyen_lieu_id = $4)`;

const thamSo = (loc, trangThai) => [trangThai, loc.tu ?? null, loc.den ?? null, loc.vung ?? null];

async function tong(q, loc, trangThai) {
  const { rows } = await q.query(
    `SELECT COALESCE(sum(thanh_tien), 0) AS doanh_so, COALESCE(sum(so_luong), 0) AS so_luong,
            count(DISTINCT don_hang_id) AS so_don
     FROM (${DONG_TINH}) d`,
    thamSo(loc, trangThai),
  );
  return camel(rows[0]);
}

// Mọi vùng đều có mặt, kể cả vùng chưa có doanh số (để biểu đồ đủ cột).
async function theoVung(q, loc, trangThai) {
  const { rows } = await q.query(
    `SELECT v.id AS vung_id, v.ten AS ten_vung,
            COALESCE(sum(d.thanh_tien), 0) AS doanh_so, COALESCE(sum(d.so_luong), 0) AS so_luong
     FROM vung_nguyen_lieu v LEFT JOIN (${DONG_TINH}) d ON d.vung_id = v.id
     WHERE ($4::int IS NULL OR v.id = $4)
     GROUP BY v.id, v.ten ORDER BY doanh_so DESC, v.id`,
    thamSo(loc, trangThai),
  );
  return rows.map(camel);
}

async function theoHangSao(q, loc, trangThai) {
  const { rows } = await q.query(
    `SELECT h.hang_sao, COALESCE(sum(d.thanh_tien), 0) AS doanh_so, COALESCE(sum(d.so_luong), 0) AS so_luong
     FROM generate_series(3, 5) AS h (hang_sao) LEFT JOIN (${DONG_TINH}) d ON d.hang_sao = h.hang_sao
     GROUP BY h.hang_sao ORDER BY h.hang_sao`,
    thamSo(loc, trangThai),
  );
  return rows.map(camel);
}

async function nhaCungCapBanChay(q, loc, trangThai, limit) {
  const { rows } = await q.query(
    `SELECT ncc.id, ncc.ten, v.ten AS ten_vung,
            sum(d.thanh_tien) AS doanh_so, sum(d.so_luong) AS so_luong, count(DISTINCT d.don_hang_id) AS so_don
     FROM (${DONG_TINH}) d
     JOIN nha_cung_cap ncc ON ncc.id = d.nha_cung_cap_id
     JOIN vung_nguyen_lieu v ON v.id = ncc.vung_id
     GROUP BY ncc.id, ncc.ten, v.ten
     ORDER BY doanh_so DESC, ncc.id
     LIMIT $5`,
    [...thamSo(loc, trangThai), limit],
  );
  return rows.map(camel);
}

module.exports = { tong, theoVung, theoHangSao, nhaCungCapBanChay };
