'use strict';

const { validate } = require('../../utils/validator');
const { badRequest } = require('../../utils/errors');

const SO_ANH_TOI_DA = 5;

// Body đánh giá. khachId lấy từ token, không nhận từ client.
function parseDanhGia(body) {
  const d = validate(body)
    .int('donHangId', { required: true, min: 1, max: 2147483647 })
    .int('sanPhamId', { required: true, min: 1, max: 2147483647 })
    .int('soSao', { required: true, min: 1, max: 5 })
    .string('noiDung', { max: 2000 })
    .array('anhUrls', { max: SO_ANH_TOI_DA })
    .done();
  const loi = [];
  const anhUrls = (d.anhUrls || []).map((u, i) => {
    const v = validate({ u }).url('u', { required: true });
    if (v.errors.length) loi.push({ truong: `anhUrls[${i}]`, thongDiep: v.errors[0].thongDiep });
    return u;
  });
  if (loi.length) throw badRequest('Dữ liệu không hợp lệ.', loi);
  return { ...d, anhUrls };
}

const parseLocDanhGia = (query) => validate(query).int('sanPhamId', { required: true, min: 1 }).done();

module.exports = { SO_ANH_TOI_DA, parseDanhGia, parseLocDanhGia };
