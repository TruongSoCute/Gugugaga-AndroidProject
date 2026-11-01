'use strict';

const { validate } = require('../../utils/validator');
const { badRequest } = require('../../utils/errors');

const TRANG_THAI_DUYET = Object.freeze(['CHO_DUYET', 'DA_DUYET', 'TU_CHOI']);

// Bộ lọc danh sách. "vung" là id vùng của nhà cung cấp. trangThai chỉ dùng cho quản trị.
function parseLoc(query, { quanTri }) {
  const v = validate(query)
    .int('vung', { min: 1 })
    .int('hangSao', { min: 3, max: 5 })
    .int('nhaCungCapId', { min: 1 })
    .string('tuKhoa', { max: 100 });
  if (quanTri) v.oneOf('trangThai', TRANG_THAI_DUYET);
  return v.done();
}

// Không nhận hangSao/trangThaiDuyet: sản phẩm mới luôn chờ duyệt, hạng sao do quản trị chốt.
function parseTao(body) {
  return validate(body)
    .int('nhaCungCapId', { required: true, min: 1 })
    .string('ten', { required: true, max: 200 })
    .string('moTa', { max: 5000 })
    .string('donViTinh', { max: 40 })
    .int('gia', { required: true, min: 1, max: 1000000000 })
    .url('anhUrl')
    .done();
}

function parseDuyet(body) {
  const d = validate(body)
    .oneOf('trangThai', ['DA_DUYET', 'TU_CHOI'], { required: true })
    .int('hangSao', { min: 3, max: 5 })
    .string('lyDo', { max: 1000 })
    .done();
  if (d.trangThai === 'DA_DUYET' && !d.hangSao) {
    throw badRequest('Dữ liệu không hợp lệ.', [{ truong: 'hangSao', thongDiep: 'Cần chọn hạng OCOP 3, 4 hoặc 5 sao.' }]);
  }
  if (d.trangThai === 'TU_CHOI' && !d.lyDo) {
    throw badRequest('Dữ liệu không hợp lệ.', [{ truong: 'lyDo', thongDiep: 'Cần ghi lý do từ chối.' }]);
  }
  return d;
}

module.exports = { TRANG_THAI_DUYET, parseLoc, parseTao, parseDuyet };
