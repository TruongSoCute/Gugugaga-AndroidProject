'use strict';

const { validate } = require('../../utils/validator');
const { badRequest } = require('../../utils/errors');

// Loại tài khoản được tự đăng ký. Tài khoản QUAN_TRI/NHAN_VIEN không bao giờ tự đăng ký được.
const LOAI_TU_DANG_KY = Object.freeze(['KHACH', 'NHA_CUNG_CAP']);

// Kiểm tra body đăng ký. Chỉ nhận các trường khai báo; vaiTro client gửi bị bỏ qua.
// loaiTaiKhoan chỉ nhận KHACH (mặc định) hoặc NHA_CUNG_CAP.
function parseDangKy(body) {
  const d = validate(body)
    .email('email', { required: true })
    .password('matKhau')
    .string('hoTen', { required: true, max: 120 })
    .phone('soDienThoai')
    .oneOf('loaiTaiKhoan', LOAI_TU_DANG_KY)
    .done();
  return { ...d, loaiTaiKhoan: d.loaiTaiKhoan || 'KHACH' };
}

function parseDangNhap(body) {
  const d = validate(body)
    .email('email', { required: true })
    .string('matKhau', { required: true, max: 200 })
    .done();
  // So sánh đúng mật khẩu đã gõ, không cắt khoảng trắng.
  return { email: d.email, matKhau: body.matKhau };
}

//* Kiểm tra dữ liệu tạo tài khoản nhân viên
//* Không nhận vaiTro từ client vì tài khoản tạo mới luôn là NHAN_VIEN
function parseTaoNhanVien(body) {
  return validate(body)
    .email('email', { required: true })
    .password('matKhau')
    .string('hoTen', { required: true, max: 120 })
    .phone('soDienThoai')
    .done();
}

//* Kiểm tra dữ liệu khóa/mở tài khoản.
//* dangHoatDong = true: mở tài khoản.
//* dangHoatDong = false: khóa tài khoản.
function parseCapNhatTrangThai(body) {
  if (
    !body ||
    typeof body !== 'object' ||
    Array.isArray(body) ||
    typeof body.dangHoatDong !== 'boolean'
  ) {
    throw badRequest('Dữ liệu không hợp lệ.', [
      {
        truong: 'dangHoatDong',
        thongDiep: 'Phải là giá trị true hoặc false.',
      },
    ]);
  }

  return { dangHoatDong: body.dangHoatDong };
}

// Dữ liệu tài khoản được phép trả về app (không bao giờ có mat_khau_hash).
const nguoiDungCongKhai = (u) => ({
  id: u.id,
  email: u.email,
  hoTen: u.hoTen,
  soDienThoai: u.soDienThoai,
  vaiTro: u.vaiTro,
});

//* bổ sung parseTaoNhanVien, parseCapNhatTrangThai
module.exports = {
  LOAI_TU_DANG_KY,
  parseDangKy,
  parseDangNhap,
  parseTaoNhanVien,
  parseCapNhatTrangThai,
  nguoiDungCongKhai
};
