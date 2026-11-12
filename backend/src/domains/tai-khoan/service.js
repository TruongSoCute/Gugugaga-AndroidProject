'use strict';

const repo = require('./repo');
const { nguoiDungCongKhai } = require('./types');
const { HttpError } = require('../../utils/errors');
const { VAI_TRO } = require('../../providers/auth');
const { phanTrang, ketQuaPhanTrang } = require('../../utils/sql');

module.exports = function createTaiKhoanService({ db, auth, password }) {
  const ketQuaDangNhap = (user) => ({ token: auth.signToken(user), nguoiDung: nguoiDungCongKhai(user) });

  return {
    // Tự đăng ký: chỉ tạo KHACH hoặc NHA_CUNG_CAP (types.js đã giới hạn), không bao giờ tạo nhân sự.
    async dangKy(d) {
      const matKhauHash = await password.hash(d.matKhau);
      const vaiTro = d.loaiTaiKhoan === VAI_TRO.NHA_CUNG_CAP ? VAI_TRO.NHA_CUNG_CAP : VAI_TRO.KHACH;
      try {
        const user = await repo.taoNguoiDung(db, {
          email: d.email, matKhauHash, hoTen: d.hoTen, soDienThoai: d.soDienThoai || null, vaiTro,
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
    //* Tạo tài khoản nhân viên
    async taoNhanVien(d) {
      const matKhauHash = await password.hash(d.matKhau);

      try {
        return await repo.taoNguoiDung(db, {
          email: d.email,
          matKhauHash,
          hoTen: d.hoTen,
          soDienThoai: d.soDienThoai || null,
          vaiTro: VAI_TRO.NHAN_VIEN,
        });
      } catch (err) {
        if (err.code === '23505') {
          throw new HttpError(
            409,
            'EMAIL_DA_TON_TAI',
            'Email đã được sử dụng.',
          );
        }
        throw err;
      }
    },

    //* Lấy danh sách tài khoản có phân trang
    async dsTaiKhoan(query) {
      const p = phanTrang(query);

      const rows = await repo.dsQuanTri(db, {
        limit: p.kichThuoc,
        offset: p.offset,
      });

      return ketQuaPhanTrang(rows, p);
    },

    //* Khóa hoặc mở tài khoản
    async capNhatTrangThai(id, d, nguoiThucHienId) {
      //* Không cho quản trị viên tự khóa tài khoản của mình
      if (
        d.dangHoatDong === false &&
        Number(id) === Number(nguoiThucHienId)
      ) {
        throw new HttpError(
          400,
          'KHONG_THE_TU_KHOA',
          'Bạn không thể tự khóa tài khoản của mình.',
        );
      }

      return db.withTransaction(async (q) => {
        //* Khóa các tài khoản quản trị đang hoạt động để tránh
        //* hai yêu cầu đồng thời cùng khóa quản trị viên cuối cùng.
        const danhSachQuanTri = await repo.dsQuanTriDangHoatDong(q);

        const taiKhoan = await repo.timDeCapNhat(q, id);

        if (!taiKhoan) {
          throw notFound('Không tìm thấy tài khoản.');
        }

        //* Không cho khóa quản trị viên cuối cùng đang hoạt động
        if (
          taiKhoan.vaiTro === VAI_TRO.QUAN_TRI &&
          taiKhoan.dangHoatDong &&
          d.dangHoatDong === false &&
          danhSachQuanTri.length <= 1
        ) {
          throw new HttpError(
            409,
            'QUAN_TRI_CUOI_CUNG',
            'Không thể khóa quản trị viên cuối cùng đang hoạt động.',
          );
        }

        return repo.capNhatTrangThai(
          q,
          id,
          d.dangHoatDong,
        );
      });
    },
  };
};
