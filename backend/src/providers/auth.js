'use strict';

// Provider xác thực và phân quyền: nơi DUY NHẤT dùng `jsonwebtoken`.
const jwt = require('jsonwebtoken');
const { HttpError } = require('../utils/errors');

const VAI_TRO = Object.freeze({ QUAN_TRI: 'QUAN_TRI', NHAN_VIEN: 'NHAN_VIEN', KHACH: 'KHACH' });
// Nhân sự dùng app Admin.
const NHAN_SU = Object.freeze([VAI_TRO.QUAN_TRI, VAI_TRO.NHAN_VIEN]);

function createAuth({ db, config }) {
  function signToken(user) {
    return jwt.sign({ sub: String(user.id), vaiTro: user.vaiTro }, config.jwtSecret, {
      algorithm: 'HS256',
      expiresIn: config.jwtExpiresIn,
    });
  }

  // Middleware kiểm tra "Authorization: Bearer <token>". Sau khi xác minh chữ ký và hạn,
  // đọc lại người dùng trong CSDL để dùng vai trò hiện tại (không tin vai trò trong token
  // nếu đã bị đổi) và chặn tài khoản đã bị khóa. Gắn kết quả vào req.user.
  async function requireAuth(req, _res, next) {
    try {
      const header = req.get('authorization') || '';
      const [scheme, token] = header.split(' ');
      if (scheme !== 'Bearer' || !token) {
        throw new HttpError(401, 'CHUA_DANG_NHAP', 'Cần đăng nhập để thực hiện thao tác này.');
      }
      let payload;
      try {
        payload = jwt.verify(token, config.jwtSecret, { algorithms: ['HS256'] });
      } catch (err) {
        const ma = err.name === 'TokenExpiredError' ? 'TOKEN_HET_HAN' : 'TOKEN_KHONG_HOP_LE';
        throw new HttpError(401, ma, 'Phiên đăng nhập không hợp lệ hoặc đã hết hạn.');
      }
      const id = Number(payload.sub);
      const { rows } = await db.query(
        'SELECT id, email, ho_ten, vai_tro, dang_hoat_dong FROM nguoi_dung WHERE id = $1',
        [Number.isSafeInteger(id) ? id : 0],
      );
      const user = rows[0];
      if (!user || !user.dang_hoat_dong) {
        throw new HttpError(401, 'TOKEN_KHONG_HOP_LE', 'Tài khoản không tồn tại hoặc đã bị khóa.');
      }
      req.user = { id: user.id, email: user.email, hoTen: user.ho_ten, vaiTro: user.vai_tro };
      next();
    } catch (err) {
      next(err);
    }
  }

  // Dùng sau requireAuth: chỉ cho các vai trò được liệt kê, còn lại trả 403.
  function requireRole(...roles) {
    return (req, _res, next) => {
      if (!req.user || !roles.includes(req.user.vaiTro)) {
        return next(new HttpError(403, 'KHONG_DU_QUYEN', 'Tài khoản không có quyền thực hiện thao tác này.'));
      }
      return next();
    };
  }

  return {
    signToken,
    requireAuth,
    requireRole,
    // Viết tắt cho các nhóm quyền hay dùng ở tầng routes.
    nhanSu: [requireAuth, requireRole(...NHAN_SU)],
    quanTri: [requireAuth, requireRole(VAI_TRO.QUAN_TRI)],
  };
}

module.exports = { createAuth, VAI_TRO, NHAN_SU };
