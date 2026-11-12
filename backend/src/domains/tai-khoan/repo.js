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

//* Danh sách tài khoản cho Admin, có phân trang.
async function dsQuanTri(q, { limit, offset }) {
  const { rows } = await q.query(
    `SELECT ${COT}, dang_hoat_dong, tao_luc,
            count(*) OVER () AS tong
     FROM nguoi_dung
     ORDER BY tao_luc DESC, id DESC
     LIMIT $1 OFFSET $2`,
    [limit, offset],
  );
  return rows;
}

//* Lấy tài khoản và khóa dòng để tránh cập nhật đồng thời.
async function timDeCapNhat(q, id) {
  const { rows } = await q.query(
    `SELECT id, vai_tro, dang_hoat_dong
     FROM nguoi_dung
     WHERE id = $1
     FOR UPDATE`,
    [id],
  );
  return camel(rows[0]);
}

//* Khóa các quản trị viên đang hoạt động.
//* Phải gọi trong transaction trước khi kiểm tra quản trị viên cuối cùng.
async function dsQuanTriDangHoatDong(q) {
  const { rows } = await q.query(
    `SELECT id
     FROM nguoi_dung
     WHERE vai_tro = 'QUAN_TRI'
       AND dang_hoat_dong = TRUE
     ORDER BY id
     FOR UPDATE`,
  );
  return rows;
}

//* Cập nhật trạng thái khóa/mở tài khoản.
async function capNhatTrangThai(q, id, dangHoatDong) {
  const { rows } = await q.query(
    `UPDATE nguoi_dung
     SET dang_hoat_dong = $2
     WHERE id = $1
     RETURNING ${COT}, dang_hoat_dong, tao_luc`,
    [id, dangHoatDong],
  );
  return camel(rows[0]);
}

//* bổ sung dsQuanTri, timDeCapNhat, dsQuanTriDangHoatDong, capNhatTrangThai
module.exports = {
  taoNguoiDung,
  timTheoEmailDeDangNhap,
  timTheoId,
  dsQuanTri,
  timDeCapNhat,
  dsQuanTriDangHoatDong,
  capNhatTrangThai,
};
