'use strict';

const { validate } = require('../../utils/validator');

// Kiểm tra body đăng ký. Chỉ nhận các trường khai báo; vaiTro client gửi bị bỏ qua.
function parseDangKy(body) {
  return validate(body)
    .email('email', { required: true })
    .password('matKhau')
    .string('hoTen', { required: true, max: 120 })
    .phone('soDienThoai')
    .done();
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

module.exports = { parseDangKy, parseDangNhap, nguoiDungCongKhai };
