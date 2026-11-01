'use strict';

// Lỗi có mã HTTP rõ ràng; middleware lỗi chuyển thành JSON { loi: { ma, thongDiep, chiTiet } }.
class HttpError extends Error {
  constructor(status, ma, thongDiep, chiTiet) {
    super(thongDiep);
    this.status = status;
    this.ma = ma;
    this.chiTiet = chiTiet;
  }
}

const notFound = (thongDiep = 'Không tìm thấy dữ liệu.') =>
  new HttpError(404, 'KHONG_TIM_THAY', thongDiep);
const conflict = (ma, thongDiep) => new HttpError(409, ma, thongDiep);
const badRequest = (thongDiep, chiTiet) =>
  new HttpError(400, 'DU_LIEU_KHONG_HOP_LE', thongDiep, chiTiet);

module.exports = { HttpError, notFound, conflict, badRequest };
