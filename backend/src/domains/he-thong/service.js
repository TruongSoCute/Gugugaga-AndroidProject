'use strict';

const repo = require('./repo');

module.exports = function createHeThongService({ db, config }) {
  // Mã commit đang chạy (không phải bí mật: mã nguồn đã công khai trên GitHub).
  const phienBan = config.phienBan ?? null;
  return {
    // Kiểm tra backend chạy và kết nối được CSDL.
    async kiemTraSucKhoe() {
      const thoiGian = new Date().toISOString();
      try {
        await repo.ping(db);
        return { ok: true, ketQua: { trangThai: 'ok', csdl: 'ok', thoiGian, phienBan } };
      } catch {
        return { ok: false, ketQua: { trangThai: 'loi', csdl: 'khong_ket_noi_duoc', thoiGian, phienBan } };
      }
    },
  };
};
