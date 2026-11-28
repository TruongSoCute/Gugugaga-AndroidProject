'use strict';

const { validate } = require('../../utils/validator');
const { badRequest } = require('../../utils/errors');

const LOAI_PHAN_ANH = Object.freeze(['HANG_GIA', 'SAI_MO_TA', 'KHAC']);
const TRANG_THAI_PHAN_ANH = Object.freeze(['MOI', 'DANG_XU_LY', 'DA_XU_LY', 'BAC_BO']);

// Quy tắc xử lý (Đề xuất): chỉ đi tới, không quay lui; DA_XU_LY và BAC_BO là kết thúc.
const CHUYEN = Object.freeze({
  MOI: ['DANG_XU_LY', 'DA_XU_LY', 'BAC_BO'],
  DANG_XU_LY: ['DA_XU_LY', 'BAC_BO'],
});
const KET_THUC = Object.freeze(['DA_XU_LY', 'BAC_BO']);

const duocChuyen = (hienTai, moi) => (CHUYEN[hienTai] || []).includes(moi);

// maTruyXuat (tùy chọn): mã lô in trên bao bì, để gắn phản ánh với đúng lô.
function parseGuiPhanAnh(body) {
  const d = validate(body)
    .int('sanPhamId', { required: true, min: 1, max: 2147483647 })
    .string('maTruyXuat', { max: 40 })
    .oneOf('loai', LOAI_PHAN_ANH, { required: true })
    .string('noiDung', { required: true, max: 2000 })
    .url('anhUrl')
    .done();
  if (d.maTruyXuat) {
    const ma = d.maTruyXuat.toUpperCase();
    if (!/^[0-9A-F]{20}$/.test(ma)) {
      throw badRequest('Dữ liệu không hợp lệ.', [{ truong: 'maTruyXuat', thongDiep: 'Mã truy xuất gồm 20 ký tự 0-9, A-F.' }]);
    }
    d.maTruyXuat = ma;
  }
  return d;
}

// Kết thúc (DA_XU_LY, BAC_BO) phải ghi kết quả để người báo biết.
function parseXuLy(body) {
  const d = validate(body)
    .oneOf('trangThai', ['DANG_XU_LY', 'DA_XU_LY', 'BAC_BO'], { required: true })
    .string('ketQuaXuLy', { max: 2000 })
    .done();
  if (KET_THUC.includes(d.trangThai) && !d.ketQuaXuLy) {
    throw badRequest('Dữ liệu không hợp lệ.', [{ truong: 'ketQuaXuLy', thongDiep: 'Cần ghi kết quả xử lý.' }]);
  }
  return d;
}

const parseLoc = (query) => validate(query)
  .oneOf('trangThai', TRANG_THAI_PHAN_ANH)
  .oneOf('loai', LOAI_PHAN_ANH)
  .done();

module.exports = {
  LOAI_PHAN_ANH, TRANG_THAI_PHAN_ANH, KET_THUC, duocChuyen, parseGuiPhanAnh, parseXuLy, parseLoc,
};
