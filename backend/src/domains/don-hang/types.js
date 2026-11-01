'use strict';

const { validate } = require('../../utils/validator');
const { badRequest } = require('../../utils/errors');

const TRANG_THAI_DON = Object.freeze(['CHO_XAC_NHAN', 'DA_XAC_NHAN', 'DANG_GIAO', 'DA_GIAO', 'DA_NHAN', 'DA_HUY']);
const HINH_THUC_GIAO = Object.freeze(['TIEU_CHUAN', 'NHANH', 'NHAN_TAI_CHO']);
const SO_LUONG_TOI_DA_MOI_DONG = 999;

// Quy tắc chuyển trạng thái (Đề xuất, xem Design_decisions.md):
// trạng thái hiện tại -> các trạng thái được phép chuyển tới, theo người thực hiện.
const CHUYEN_NHAN_SU = Object.freeze({
  CHO_XAC_NHAN: ['DA_XAC_NHAN', 'DA_HUY'],
  DA_XAC_NHAN: ['DANG_GIAO', 'DA_HUY'],
  DANG_GIAO: ['DA_GIAO'],
});
// Khách chỉ được hủy đơn chưa xác nhận và xác nhận đã nhận hàng.
const CHUYEN_KHACH = Object.freeze({
  CHO_XAC_NHAN: ['DA_HUY'],
  DA_GIAO: ['DA_NHAN'],
});

// Kết quả: 'OK', 'KHONG_DU_QUYEN' (vai trò không bao giờ được chuyển tới trạng thái này)
// hoặc 'SAI_TRANG_THAI' (được phép nhưng không từ trạng thái hiện tại).
function kiemTraChuyen(hienTai, moi, { nhanSu }) {
  const bang = nhanSu ? CHUYEN_NHAN_SU : CHUYEN_KHACH;
  const duocToi = new Set(Object.values(bang).flat());
  if (!duocToi.has(moi)) return 'KHONG_DU_QUYEN';
  return (bang[hienTai] || []).includes(moi) ? 'OK' : 'SAI_TRANG_THAI';
}

// Chia số lượng cần cho các lô theo FIFO: lô sản xuất trước bán trước.
// Trả null nếu tổng tồn không đủ.
function chiaLoFifo(loCuaSanPham, canLay) {
  const lo = [...loCuaSanPham].sort((a, b) => (a.ngaySanXuat < b.ngaySanXuat ? -1 : a.ngaySanXuat > b.ngaySanXuat ? 1 : a.id - b.id));
  const ketQua = [];
  let conCan = canLay;
  for (const l of lo) {
    if (conCan === 0) break;
    const lay = Math.min(conCan, l.soLuongCon);
    ketQua.push({ loId: l.id, soLuong: lay });
    conCan -= lay;
  }
  return conCan === 0 ? ketQua : null;
}

function parseGio(body) {
  return validate(body).int('soLuong', { required: true, min: 1, max: SO_LUONG_TOI_DA_MOI_DONG }).done();
}

// Đặt hàng: chỉ nhận sản phẩm và số lượng. Giá, phí giao, tổng tiền và lô do backend quyết định;
// các trường như gia, tongTien, loId client tự gửi đều bị bỏ qua.
// Không gửi cacDong thì đặt toàn bộ giỏ hàng.
function parseDatHang(body) {
  const d = validate(body)
    .oneOf('hinhThucGiao', HINH_THUC_GIAO, { required: true })
    .string('tenNguoiNhan', { required: true, max: 120 })
    .phone('sdtNguoiNhan', { required: true })
    .string('diaChiGiao', { required: true, max: 500 })
    .string('ghiChu', { max: 1000 })
    .array('cacDong', { max: 50 })
    .done();
  if (!d.cacDong) return d;

  const loi = [];
  const gop = new Map();
  d.cacDong.forEach((dong, i) => {
    const v = validate(dong)
      .int('sanPhamId', { required: true, min: 1, max: 2147483647 })
      .int('soLuong', { required: true, min: 1, max: SO_LUONG_TOI_DA_MOI_DONG });
    v.errors.forEach((e) => loi.push({ truong: `cacDong[${i}].${e.truong}`, thongDiep: e.thongDiep }));
    if (!v.errors.length) {
      // Cùng một sản phẩm gửi hai lần thì cộng dồn số lượng.
      gop.set(v.out.sanPhamId, (gop.get(v.out.sanPhamId) || 0) + v.out.soLuong);
    }
  });
  if (!d.cacDong.length) loi.push({ truong: 'cacDong', thongDiep: 'Cần ít nhất một sản phẩm.' });
  if (loi.length) throw badRequest('Dữ liệu không hợp lệ.', loi);
  return { ...d, cacDong: [...gop].map(([sanPhamId, soLuong]) => ({ sanPhamId, soLuong })) };
}

// Nhân sự hủy đơn phải ghi lý do để khách biết.
function parseDoiTrangThai(body, { nhanSu }) {
  const d = validate(body)
    .oneOf('trangThai', TRANG_THAI_DON, { required: true })
    .string('ghiChu', { max: 1000 })
    .done();
  if (nhanSu && d.trangThai === 'DA_HUY' && !d.ghiChu) {
    throw badRequest('Dữ liệu không hợp lệ.', [{ truong: 'ghiChu', thongDiep: 'Cần ghi lý do hủy đơn.' }]);
  }
  return d;
}

function parseLocDon(query, { quanTri }) {
  const v = validate(query).oneOf('trangThai', TRANG_THAI_DON);
  if (quanTri) v.int('khachId', { min: 1 });
  return v.done();
}

module.exports = {
  TRANG_THAI_DON, HINH_THUC_GIAO, kiemTraChuyen, chiaLoFifo,
  parseGio, parseDatHang, parseDoiTrangThai, parseLocDon,
};
