'use strict';

const { validate } = require('../../utils/validator');
const { badRequest } = require('../../utils/errors');

const TRANG_THAI_DUYET = Object.freeze(['CHO_DUYET', 'DA_DUYET', 'TU_CHOI']);

function parseChungNhan(list) {
  return list.map((item, i) => {
    const d = validate(item)
      .string('loai', { required: true, max: 60 })
      .string('soHieu', { required: true, max: 80 })
      .date('ngayCap', { required: true })
      .date('ngayHetHan')
      .url('anhUrl')
      .done();
    if (d.ngayHetHan && d.ngayHetHan <= d.ngayCap) {
      throw badRequest('Dữ liệu không hợp lệ.', [
        { truong: `chungNhan[${i}].ngayHetHan`, thongDiep: 'Ngày hết hạn phải sau ngày cấp.' },
      ]);
    }
    return d;
  });
}

// Body tạo hồ sơ. Không nhận trangThaiDuyet: hồ sơ mới luôn chờ duyệt.
function parseTaoHoSo(body) {
  const d = validate(body)
    .string('ten', { required: true, max: 200 })
    .string('nguoiDaiDien', { required: true, max: 120 })
    .phone('soDienThoai', { required: true })
    .string('diaChi', { required: true, max: 500 })
    .int('vungId', { required: true, min: 1 })
    .url('anhCoSoUrl')
    .array('chungNhan', { max: 10 })
    .done();
  return { ...d, chungNhan: parseChungNhan(d.chungNhan || []) };
}

// Body duyệt: từ chối phải có lý do.
function parseDuyet(body) {
  const d = validate(body)
    .oneOf('trangThai', ['DA_DUYET', 'TU_CHOI'], { required: true })
    .string('lyDo', { max: 1000 })
    .done();
  if (d.trangThai === 'TU_CHOI' && !d.lyDo) {
    throw badRequest('Dữ liệu không hợp lệ.', [{ truong: 'lyDo', thongDiep: 'Cần ghi lý do từ chối.' }]);
  }
  return d;
}

const parseLocCongKhai = (query) => validate(query).int('vung', { min: 1 }).done();

const parseLocQuanTri = (query) => validate(query)
  .oneOf('trangThai', TRANG_THAI_DUYET)
  .int('vung', { min: 1 })
  .done();

module.exports = { TRANG_THAI_DUYET, parseTaoHoSo, parseDuyet, parseLocCongKhai, parseLocQuanTri };
