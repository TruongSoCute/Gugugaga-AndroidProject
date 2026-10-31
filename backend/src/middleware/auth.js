'use strict';

const jwt = require('jsonwebtoken');
const { HttpError } = require('../errors');

const VAI_TRO = Object.freeze({ QUAN_TRI: 'QUAN_TRI', NHAN_VIEN: 'NHAN_VIEN', KHACH: 'KHACH' });
// Nhân sự dùng app Admin.
const NHAN_SU = [VAI_TRO.QUAN_TRI, VAI_TRO.NHAN_VIEN];

function signToken(config, user) {
  return jwt.sign({ sub: String(user.id), vaiTro: user.vai_tro }, config.jwtSecret, {
    algorithm: 'HS256',
    expiresIn: config.jwtExpiresIn,
  });
}

// Kiểm tra header "Authorization: Bearer <token>". Sau khi xác minh chữ ký và hạn,
// đọc lại người dùng trong CSDL để dùng vai trò hiện tại (không tin vai trò trong token
// nếu đã bị đổi) và chặn tài khoản đã bị khóa.
function requireAuth({ pool, config }) {
  return async (req, _res, next) => {
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
      const { rows } = await pool.query(
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
  };
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

module.exports = { VAI_TRO, NHAN_SU, signToken, requireAuth, requireRole };
