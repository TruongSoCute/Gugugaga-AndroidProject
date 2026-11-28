'use strict';

const { withApiColumns, camel } = require('../../utils/sql');

const COT = 'id, email, full_name, phone_number, role';

async function taoNguoiDung(q, { email, matKhauHash, hoTen, soDienThoai, vaiTro }) {
  const { rows } = withApiColumns(await q.query(
    `INSERT INTO users (email, password_hash, full_name, phone_number, role)
     VALUES ($1, $2, $3, $4, $5) RETURNING ${COT}`,
    [email, matKhauHash, hoTen, soDienThoai, vaiTro],
  ));
  return camel(rows[0]);
}

// Có kèm mat_khau_hash: chỉ dùng nội bộ để so sánh khi đăng nhập.
async function timTheoEmailDeDangNhap(q, email) {
  const { rows } = withApiColumns(await q.query(
    `SELECT ${COT}, password_hash, is_active FROM users WHERE email = $1`,
    [email],
  ));
  return camel(rows[0]);
}

async function timTheoId(q, id) {
  const { rows } = withApiColumns(await q.query(`SELECT ${COT} FROM users WHERE id = $1`, [id]));
  return camel(rows[0]);
}

//* Danh sách tài khoản cho Admin, có phân trang.
async function dsQuanTri(q, { limit, offset }) {
  const { rows } = withApiColumns(await q.query(
    `SELECT ${COT}, is_active, created_at,
            count(*) OVER () AS tong
     FROM users
     ORDER BY created_at DESC, id DESC
     LIMIT $1 OFFSET $2`,
    [limit, offset],
  ));
  return rows;
}

//* Lấy tài khoản và khóa dòng để tránh cập nhật đồng thời.
async function timDeCapNhat(q, id) {
  const { rows } = withApiColumns(await q.query(
    `SELECT id, role, is_active
     FROM users
     WHERE id = $1
     FOR UPDATE`,
    [id],
  ));
  return camel(rows[0]);
}

//* Khóa các quản trị viên đang hoạt động.
//* Phải gọi trong transaction trước khi kiểm tra quản trị viên cuối cùng.
async function dsQuanTriDangHoatDong(q) {
  const { rows } = withApiColumns(await q.query(
    `SELECT id
     FROM users
     WHERE role = 'QUAN_TRI'
       AND is_active = TRUE
     ORDER BY id
     FOR UPDATE`,
  ));
  return rows;
}

//* Cập nhật trạng thái khóa/mở tài khoản.
async function capNhatTrangThai(q, id, dangHoatDong) {
  const { rows } = withApiColumns(await q.query(
    `UPDATE users
     SET is_active = $2
     WHERE id = $1
     RETURNING ${COT}, is_active, created_at`,
    [id, dangHoatDong],
  ));
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
