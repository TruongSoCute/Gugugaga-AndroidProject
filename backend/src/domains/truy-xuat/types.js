'use strict';

const { validate } = require('../../utils/validator');
const { badRequest } = require('../../utils/errors');

// Mã truy xuất: 10 byte ngẫu nhiên -> 20 ký tự hex in hoa (80 bit), khớp CHECK trong schema.sql.
const MA_TRUY_XUAT_SO_BYTE = 10;
const MA_TRUY_XUAT_REGEX = /^[0-9A-F]{20}$/;

// Chuẩn hóa mã người dùng quét/gõ; trả null nếu sai định dạng.
function chuanHoaMa(raw) {
  const ma = String(raw).trim().toUpperCase();
  return MA_TRUY_XUAT_REGEX.test(ma) ? ma : null;
}

function parseBuoc(item) {
  return validate(item)
    .int('thuTu', { min: 1, max: 100 })
    .string('tenBuoc', { required: true, max: 120 })
    .string('moTa', { max: 2000 })
    .datetime('thoiDiem', { required: true })
    .url('anhUrl')
    .done();
}

// Body tạo lô. Không nhận maTruyXuat: mã do server sinh.
function parseTaoLo(body) {
  const d = validate(body)
    .int('sanPhamId', { required: true, min: 1 })
    .date('ngaySanXuat', { required: true })
    .date('hanSuDung', { required: true })
    .int('soLuong', { required: true, min: 1, max: 10000000 })
    .int('vungNguyenLieuId', { min: 1 })
    .string('nguoiSanXuat', { required: true, max: 120 })
    .url('anhHienTruongUrl')
    .string('ghiChu', { max: 2000 })
    .array('cacBuoc', { max: 30 })
    .done();
  if (d.hanSuDung <= d.ngaySanXuat) {
    throw badRequest('Dữ liệu không hợp lệ.', [{ truong: 'hanSuDung', thongDiep: 'Hạn sử dụng phải sau ngày sản xuất.' }]);
  }
  const cacBuoc = (d.cacBuoc || []).map(parseBuoc);
  // Gán thứ tự 1, 2, 3... nếu không gửi; không cho trùng thứ tự.
  cacBuoc.forEach((b, i) => { if (!b.thuTu) b.thuTu = i + 1; });
  if (new Set(cacBuoc.map((b) => b.thuTu)).size !== cacBuoc.length) {
    throw badRequest('Dữ liệu không hợp lệ.', [{ truong: 'cacBuoc', thongDiep: 'Thứ tự các bước bị trùng.' }]);
  }
  return { ...d, cacBuoc };
}

const parseLocLo = (query) => validate(query).int('sanPhamId', { min: 1 }).done();

module.exports = { MA_TRUY_XUAT_SO_BYTE, MA_TRUY_XUAT_REGEX, chuanHoaMa, parseBuoc, parseTaoLo, parseLocLo };
