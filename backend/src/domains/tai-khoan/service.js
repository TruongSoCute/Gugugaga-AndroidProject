'use strict';

const repo = require('./repo');
const { nguoiDungCongKhai } = require('./types');
const { HttpError } = require('../../utils/errors');
const { VAI_TRO } = require('../../providers/auth');

module.exports = function createTaiKhoanService({ db, auth, password }) {
  const ketQuaDangNhap = (user) => ({ token: auth.signToken(user), nguoiDung: nguoiDungCongKhai(user) });

  return {
    // Khách tự đăng ký: vai trò luôn là KHACH.
    async dangKy(d) {
      const matKhauHash = await password.hash(d.matKhau);
      try {
        const user = await repo.taoNguoiDung(db, {
          email: d.email, matKhauHash, hoTen: d.hoTen, soDienThoai: d.soDienThoai || null, vaiTro: VAI_TRO.KHACH,
        });
        return ketQuaDangNhap(user);
      } catch (err) {
        if (err.code === '23505') throw new HttpError(409, 'EMAIL_DA_TON_TAI', 'Email đã được đăng ký.');
        throw err;
      }
    },

    // Sai email hay sai mật khẩu đều trả cùng một lỗi để không lộ email nào tồn tại.
    async dangNhap({ email, matKhau }) {
      const user = await repo.timTheoEmailDeDangNhap(db, email);
      const ok = await password.compare(matKhau, user ? user.matKhauHash : null);
      if (!user || !ok) throw new HttpError(401, 'SAI_THONG_TIN_DANG_NHAP', 'Email hoặc mật khẩu không đúng.');
      if (!user.dangHoatDong) throw new HttpError(403, 'TAI_KHOAN_BI_KHOA', 'Tài khoản đã bị khóa.');
      return ketQuaDangNhap(user);
    },

    async thongTin(id) {
      return nguoiDungCongKhai(await repo.timTheoId(db, id));
    },
  };
};
