'use strict';

const { HttpError } = require('../errors');

const TAG = '[OCOP-API]';

// Chuyển mọi lỗi thành JSON thống nhất. Lỗi không lường trước trả 500 và không lộ
// chi tiết nội bộ (câu SQL, stack) cho client.
// eslint-disable-next-line no-unused-vars
function errorHandler(err, req, res, _next) {
  let e = err;

  if (!(e instanceof HttpError)) {
    if (e.type === 'entity.parse.failed') {
      e = new HttpError(400, 'JSON_KHONG_HOP_LE', 'Nội dung gửi lên không phải JSON hợp lệ.');
    } else if (e.type === 'entity.too.large') {
      e = new HttpError(413, 'DU_LIEU_QUA_LON', 'Dữ liệu gửi lên quá lớn.');
    } else if (e.code === '23505') {
      e = new HttpError(409, 'TRUNG_DU_LIEU', 'Dữ liệu bị trùng với bản ghi đã có.');
    } else if (e.code === '23503') {
      e = new HttpError(409, 'RANG_BUOC_KHOA_NGOAI', 'Dữ liệu tham chiếu không tồn tại hoặc đang được sử dụng.');
    } else if (e.code === '23514' || e.code === '22P02' || e.code === '22007' || e.code === '22008') {
      e = new HttpError(400, 'DU_LIEU_KHONG_HOP_LE', 'Dữ liệu vi phạm ràng buộc hợp lệ.');
    }
  }

  if (e instanceof HttpError) {
    const body = { loi: { ma: e.ma, thongDiep: e.message } };
    if (e.chiTiet) body.loi.chiTiet = e.chiTiet;
    return res.status(e.status).json(body);
  }

  console.error(TAG, req.method, req.originalUrl, err);
  return res.status(500).json({ loi: { ma: 'LOI_MAY_CHU', thongDiep: 'Lỗi máy chủ, vui lòng thử lại sau.' } });
}

module.exports = { errorHandler, TAG };
