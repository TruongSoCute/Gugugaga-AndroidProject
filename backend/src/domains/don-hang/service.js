'use strict';

const repo = require('./repo');
const { kiemTraChuyen, chiaLoFifo, HINH_THUC_GIAO } = require('./types');
const { PHI_GIAO, TEN_HINH_THUC_GIAO } = require('./config');
const { HttpError, notFound, badRequest } = require('../../utils/errors');
const { ketQuaPhanTrang } = require('../../utils/sql');

module.exports = function createDonHangService({ db }) {
  async function chiTietDon(id, nguoiXem) {
    const don = await repo.timDon(db, id);
    // Khách xem đơn của người khác nhận 404 (không lộ là đơn có tồn tại).
    if (!don || (!nguoiXem.nhanSu && don.khachId !== nguoiXem.id)) throw notFound('Không tìm thấy đơn hàng.');
    const [chiTiet, lichSu] = await Promise.all([repo.chiTietDon(db, id), repo.lichSuDon(db, id)]);
    return { ...don, chiTiet, lichSu };
  }

  async function gioHang(khachId) {
    const dong = await repo.gioHang(db, khachId);
    // Tạm tính chỉ cộng sản phẩm còn đang bán; giá luôn là giá hiện hành trong CSDL.
    const tamTinh = dong.filter((d) => d.dangBan).reduce((s, d) => s + d.thanhTien, 0);
    return { duLieu: dong, tamTinh };
  }

  return {
    hinhThucGiao() {
      return HINH_THUC_GIAO.map((ma) => ({ ma, ten: TEN_HINH_THUC_GIAO[ma], phiGiao: PHI_GIAO[ma] }));
    },

    // ---- Giỏ hàng ----
    gioHang,

    async datVaoGio(khachId, sanPhamId, soLuong) {
      if (!(await repo.sanPhamDangBan(db, sanPhamId))) throw notFound('Không tìm thấy sản phẩm đang bán.');
      await repo.datVaoGio(db, khachId, sanPhamId, soLuong);
      return gioHang(khachId);
    },

    async xoaKhoiGio(khachId, sanPhamId) {
      if (!(await repo.xoaKhoiGio(db, khachId, [sanPhamId]))) throw notFound('Sản phẩm không có trong giỏ.');
      return gioHang(khachId);
    },

    // ---- Đặt đơn ----
    // Một transaction: kiểm tra sản phẩm đang bán, khóa lô, chia lô FIFO, trừ tồn, lưu đơn,
    // chi tiết, lịch sử và xóa giỏ. Lỗi ở bất kỳ bước nào thì hoàn tác tất cả.
    async datHang(khachId, d) {
      const donId = await db.withTransaction(async (client) => {
        const tuGio = !d.cacDong;
        const dong = tuGio ? await repo.khoaGio(client, khachId) : d.cacDong;
        if (!dong.length) {
          throw badRequest('Dữ liệu không hợp lệ.', [{ truong: 'cacDong', thongDiep: 'Giỏ hàng trống.' }]);
        }
        const ids = dong.map((x) => x.sanPhamId);

        const sanPham = new Map((await repo.giaSanPhamDangBan(client, ids)).map((sp) => [sp.id, sp]));
        const khongBan = ids.filter((id) => !sanPham.has(id));
        if (khongBan.length) {
          throw new HttpError(409, 'SAN_PHAM_KHONG_CON_BAN', 'Có sản phẩm không còn được bán.',
            khongBan.map((id) => ({ truong: 'sanPhamId', thongDiep: `Sản phẩm ${id} không còn được bán.` })));
        }

        const lo = await repo.khoaLoConBan(client, ids);
        const chiTiet = [];
        const thieu = [];
        for (const x of dong) {
          const sp = sanPham.get(x.sanPhamId);
          const loCuaSp = lo.filter((l) => l.sanPhamId === x.sanPhamId);
          const chia = chiaLoFifo(loCuaSp, x.soLuong);
          if (!chia) {
            const con = loCuaSp.reduce((s, l) => s + l.soLuongCon, 0);
            thieu.push({ truong: 'sanPhamId', thongDiep: `"${sp.ten}" chỉ còn ${con}.`, sanPhamId: x.sanPhamId, conLai: con });
            continue;
          }
          for (const c of chia) chiTiet.push({ ...c, sanPhamId: x.sanPhamId, donGia: sp.gia });
        }
        if (thieu.length) throw new HttpError(409, 'KHONG_DU_HANG', 'Không đủ hàng cho đơn này.', thieu);

        const tienHang = chiTiet.reduce((s, c) => s + c.soLuong * c.donGia, 0);
        const phiGiao = PHI_GIAO[d.hinhThucGiao];
        const id = await repo.themDon(client, {
          ...d, khachId, phiGiao, tienHang, tongTien: tienHang + phiGiao,
        });
        for (const c of chiTiet) {
          await repo.themChiTiet(client, id, c);
          await repo.truTonLo(client, c.loId, c.soLuong);
        }
        await repo.themLichSu(client, id, 'CHO_XAC_NHAN', 'Khách đặt hàng.', khachId);
        if (tuGio) await repo.xoaKhoiGio(client, khachId, ids);
        return id;
      });
      return chiTietDon(donId, { id: khachId, nhanSu: false });
    },

    // ---- Xem đơn ----
    async dsDon(loc, p, nguoiXem) {
      const khachId = nguoiXem.nhanSu ? loc.khachId : nguoiXem.id;
      const rows = await repo.dsDon(db, { khachId, trangThai: loc.trangThai, limit: p.kichThuoc, offset: p.offset });
      return ketQuaPhanTrang(rows, p);
    },

    chiTietDon,

    // ---- Chuyển trạng thái ----
    // Nhân sự: xác nhận, giao, đã giao, hủy (trước khi giao). Khách: hủy đơn chưa xác nhận
    // của mình, xác nhận đã nhận hàng. Hủy đơn thì hoàn lại tồn cho đúng các lô đã trừ.
    async doiTrangThai(id, d, nguoi) {
      await db.withTransaction(async (client) => {
        const don = await repo.khoaDon(client, id);
        if (!don || (!nguoi.nhanSu && don.khachId !== nguoi.id)) throw notFound('Không tìm thấy đơn hàng.');

        const kq = kiemTraChuyen(don.trangThai, d.trangThai, { nhanSu: nguoi.nhanSu });
        if (kq === 'KHONG_DU_QUYEN') {
          throw new HttpError(403, 'KHONG_DU_QUYEN', 'Tài khoản không có quyền chuyển đơn sang trạng thái này.');
        }
        if (kq === 'SAI_TRANG_THAI') {
          throw new HttpError(409, 'TRANG_THAI_KHONG_HOP_LE',
            `Không thể chuyển đơn từ ${don.trangThai} sang ${d.trangThai}.`);
        }

        if (d.trangThai === 'DA_HUY') {
          const dong = await repo.soLuongTheoLo(client, id);
          await repo.khoaLoTheoId(client, dong.map((x) => x.loId));
          for (const x of dong) await repo.truTonLo(client, x.loId, -x.soLuong);
        }
        await repo.capNhatTrangThai(client, id, d.trangThai);
        await repo.themLichSu(client, id, d.trangThai, d.ghiChu, nguoi.id);
      });
      return chiTietDon(id, nguoi);
    },
  };
};
