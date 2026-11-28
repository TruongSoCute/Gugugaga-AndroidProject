'use strict';

const { LOAI_ANH, nhanDangAnh, thuMuc } = require('./types');
const { HttpError } = require('../../utils/errors');

module.exports = function createTaiLenService({ storage, random, logger }) {
  return {
    // Tên tệp ngẫu nhiên (không dùng tên app gửi) để không đoán được và không ghi đè tệp khác.
    async taiAnh(buffer, mucDich, nguoiDungId) {
      if (!storage.daCauHinh) {
        throw new HttpError(503, 'CHUA_CAU_HINH_LUU_ANH', 'Máy chủ chưa cấu hình lưu ảnh; tạm thời nhập đường dẫn ảnh.');
      }
      const duoi = nhanDangAnh(buffer);
      if (!duoi) throw new HttpError(415, 'KHONG_PHAI_ANH', 'Chỉ nhận ảnh JPEG, PNG hoặc WebP.');
      const duongDan = `${thuMuc(mucDich)}/${nguoiDungId}-${random.hexUpper(12).toLowerCase()}.${duoi}`;
      try {
        return { url: await storage.taiLen(duongDan, buffer, LOAI_ANH[duoi]) };
      } catch (err) {
        logger.error('Tải ảnh thất bại', err.message);
        throw new HttpError(502, 'LUU_ANH_THAT_BAI', 'Không lưu được ảnh, vui lòng thử lại.');
      }
    },
  };
};
