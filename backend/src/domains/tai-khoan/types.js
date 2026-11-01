'use strict';

const { validate } = require('../../utils/validator');

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

// Dữ liệu tài khoản được phép trả về app (không bao giờ có mat_khau_hash).
const nguoiDungCongKhai = (u) => ({
  id: u.id, email: u.email, hoTen: u.hoTen, soDienThoai: u.soDienThoai, vaiTro: u.vaiTro,
});

module.exports = { LOAI_TU_DANG_KY, parseDangKy, parseDangNhap, nguoiDungCongKhai };
