'use strict';

// Provider HTTP dùng chung: chuyển mọi lỗi thành JSON { loi: { ma, thongDiep, chiTiet } }
// và trả 404 cho đường dẫn không tồn tại. Lỗi không lường trước trả 500 và không lộ
// chi tiết nội bộ (câu SQL, stack) cho client.
const { HttpError } = require('../utils/errors');

function chuyenLoi(e) {
  if (e instanceof HttpError) return e;
  if (e.type === 'entity.parse.failed') {
    return new HttpError(400, 'JSON_KHONG_HOP_LE', 'Nội dung gửi lên không phải JSON hợp lệ.');
  }
  if (e.type === 'entity.too.large') {
    return new HttpError(413, 'DU_LIEU_QUA_LON', 'Dữ liệu gửi lên quá lớn.');
  }
  if (e.code === '23505') return new HttpError(409, 'TRUNG_DU_LIEU', 'Dữ liệu bị trùng với bản ghi đã có.');
  if (e.code === '23503') {
    return new HttpError(409, 'RANG_BUOC_KHOA_NGOAI', 'Dữ liệu tham chiếu không tồn tại hoặc đang được sử dụng.');
  }
  if (['23514', '22P02', '22007', '22008'].includes(e.code)) {
    return new HttpError(400, 'DU_LIEU_KHONG_HOP_LE', 'Dữ liệu vi phạm ràng buộc hợp lệ.');
  }
  return null;
}

function createHttp({ logger }) {
  // eslint-disable-next-line no-unused-vars
  function errorHandler(err, req, res, _next) {
    const e = chuyenLoi(err);
    if (e) {
      const body = { loi: { ma: e.ma, thongDiep: e.message } };
      if (e.chiTiet) body.loi.chiTiet = e.chiTiet;
      return res.status(e.status).json(body);
    }
    logger.error(req.method, req.originalUrl, err);
    return res.status(500).json({ loi: { ma: 'LOI_MAY_CHU', thongDiep: 'Lỗi máy chủ, vui lòng thử lại sau.' } });
  }

  function notFoundHandler(req, _res, next) {
    next(new HttpError(404, 'KHONG_TIM_THAY_DUONG_DAN', `Không có API ${req.method} ${req.path}.`));
  }

  // Địa chỉ gốc công khai của backend (dùng tạo nội dung QR).
  function baseUrl(config, req) {
    return config.publicBaseUrl || `${req.protocol}://${req.get('host')}`;
  }

  return { errorHandler, notFoundHandler, baseUrl };
}

module.exports = { createHttp };
