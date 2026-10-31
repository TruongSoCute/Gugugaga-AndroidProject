'use strict';

const { camel } = require('../../utils/sql');

const COT = 'id, email, ho_ten, so_dien_thoai, vai_tro';

async function taoNguoiDung(q, { email, matKhauHash, hoTen, soDienThoai, vaiTro }) {
  const { rows } = await q.query(
    `INSERT INTO nguoi_dung (email, mat_khau_hash, ho_ten, so_dien_thoai, vai_tro)
     VALUES ($1, $2, $3, $4, $5) RETURNING ${COT}`,
    [email, matKhauHash, hoTen, soDienThoai, vaiTro],
  );
  return camel(rows[0]);
}

// Có kèm mat_khau_hash: chỉ dùng nội bộ để so sánh khi đăng nhập.
async function timTheoEmailDeDangNhap(q, email) {
  const { rows } = await q.query(
    `SELECT ${COT}, mat_khau_hash, dang_hoat_dong FROM nguoi_dung WHERE email = $1`,
    [email],
  );
  return camel(rows[0]);
}

async function timTheoId(q, id) {
  const { rows } = await q.query(`SELECT ${COT} FROM nguoi_dung WHERE id = $1`, [id]);
  return camel(rows[0]);
}

module.exports = { taoNguoiDung, timTheoEmailDeDangNhap, timTheoId };
