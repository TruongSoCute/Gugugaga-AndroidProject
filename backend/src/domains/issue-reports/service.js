'use strict';

const repo = require('./repo');
const { KET_THUC, duocChuyen } = require('./types');
const { HttpError, notFound, badRequest } = require('../../utils/errors');
const { ketQuaPhanTrang } = require('../../utils/sql');

module.exports = function createPhanAnhService({ db }) {
  // Khách chỉ xem phản ánh của mình; người khác nhận 404.
  async function chiTiet(id, nguoiXem) {
    const bc = await repo.timTheoId(db, id);
    if (!bc || (!nguoiXem.nhanSu && bc.nguoiBaoId !== nguoiXem.id)) throw notFound('Không tìm thấy phản ánh.');
    if (!nguoiXem.nhanSu) delete bc.emailNguoiBao;
    return bc;
  }

  return {
    // Gắn phản ánh với lô khi khách nhập/quét mã trên bao bì; lô phải thuộc đúng sản phẩm.
    async gui(nguoiBaoId, d) {
      if (!(await repo.sanPhamTonTai(db, d.sanPhamId))) throw notFound('Không tìm thấy sản phẩm.');
      let loId = null;
      if (d.maTruyXuat) {
        const lo = await repo.loTheoMa(db, d.maTruyXuat);
        if (!lo || lo.sanPhamId !== d.sanPhamId) {
          throw badRequest('Dữ liệu không hợp lệ.', [{ truong: 'maTruyXuat', thongDiep: 'Mã lô không thuộc sản phẩm này.' }]);
        }
        loId = lo.id;
      }
      const id = await repo.them(db, { ...d, nguoiBaoId, loId });
      return chiTiet(id, { id: nguoiBaoId, nhanSu: false });
    },

    async ds(loc, p, nguoiXem) {
      const nguoiBaoId = nguoiXem.nhanSu ? null : nguoiXem.id;
      const rows = await repo.ds(db, { ...loc, nguoiBaoId, limit: p.kichThuoc, offset: p.offset });
      return ketQuaPhanTrang(rows, p);
    },

    chiTiet,

    // Nhân sự xử lý: chỉ đi tới (MOI -> DANG_XU_LY -> DA_XU_LY/BAC_BO), khóa dòng khi cập nhật.
    async xuLy(id, d, nguoiXuLyId) {
      await db.withTransaction(async (client) => {
        const bc = await repo.khoa(client, id);
        if (!bc) throw notFound('Không tìm thấy phản ánh.');
        if (!duocChuyen(bc.trangThai, d.trangThai)) {
          throw new HttpError(409, 'TRANG_THAI_KHONG_HOP_LE', `Không thể chuyển phản ánh từ ${bc.trangThai} sang ${d.trangThai}.`);
        }
        await repo.capNhatXuLy(client, id, { ...d, nguoiXuLyId, ketThuc: KET_THUC.includes(d.trangThai) });
      });
      return chiTiet(id, { nhanSu: true });
    },
  };
};
