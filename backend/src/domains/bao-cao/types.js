'use strict';

const { validate } = require('../../utils/validator');
const { badRequest } = require('../../utils/errors');

// Trạng thái đơn được tính vào doanh số (Đề xuất, Design_decisions.md): hàng đã giao tới khách.
const TRANG_THAI_TINH_DOANH_SO = Object.freeze(['DA_GIAO', 'DA_NHAN']);
const SO_NHA_CUNG_CAP_TOP = 5;

// tu/den: ngày đặt đơn theo giờ Việt Nam, YYYY-MM-DD, tính cả hai đầu. vung: vùng của lô đã giao.
function parseLocDoanhSo(query) {
  const d = validate(query)
    .date('tu')
    .date('den')
    .int('vung', { min: 1 })
    .done();
  if (d.tu && d.den && d.tu > d.den) {
    throw badRequest('Dữ liệu không hợp lệ.', [{ truong: 'den', thongDiep: 'Ngày kết thúc phải từ ngày bắt đầu trở đi.' }]);
  }
  return d;
}

module.exports = { TRANG_THAI_TINH_DOANH_SO, SO_NHA_CUNG_CAP_TOP, parseLocDoanhSo };
