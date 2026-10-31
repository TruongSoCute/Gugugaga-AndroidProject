'use strict';

const repo = require('./repo');
const { notFound, conflict, badRequest } = require('../../utils/errors');
const { ketQuaPhanTrang } = require('../../utils/sql');

// deps.nhaCungCap: service của miền nhà cung cấp, truyền vào từ app wiring
// (miền này không import trực tiếp miền khác).
module.exports = function createSanPhamService({ db }, { nhaCungCap }) {
  async function chiTiet(id, { quanTri }) {
    const sp = await repo.timTheoId(db, id, { quanTri });
    if (!sp) throw notFound('Không tìm thấy sản phẩm.');
    const [chungNhan, danhGiaGanDay] = await Promise.all([
      nhaCungCap.dsChungNhan(sp.nhaCungCapId),
      repo.danhGiaGanDay(db, id),
    ]);
    return { ...sp, chungNhan, danhGiaGanDay };
  }

  return {
    async danhSach(loc, p, { quanTri }) {
      const rows = await repo.danhSach(db, loc, { quanTri, limit: p.kichThuoc, offset: p.offset });
      return ketQuaPhanTrang(rows, p);
    },

    chiTiet,

    // Sản phẩm mới luôn CHO_DUYET; không thêm cho nhà cung cấp đã bị từ chối.
    async tao(d, nguoiTaoId) {
      const trangThaiNcc = await repo.trangThaiNhaCungCap(db, d.nhaCungCapId);
      if (!trangThaiNcc) {
        throw badRequest('Dữ liệu không hợp lệ.', [{ truong: 'nhaCungCapId', thongDiep: 'Nhà cung cấp không tồn tại.' }]);
      }
      if (trangThaiNcc === 'TU_CHOI') {
        throw conflict('NHA_CUNG_CAP_BI_TU_CHOI', 'Nhà cung cấp đã bị từ chối, không thể thêm sản phẩm.');
      }
      const id = await repo.them(db, d, nguoiTaoId);
      return chiTiet(id, { quanTri: true });
    },

    // Duyệt sản phẩm cần nhà cung cấp đã duyệt; chốt hạng OCOP 3–5 sao.
    async duyet(id, d, nguoiDuyetId) {
      await db.withTransaction(async (client) => {
        const sp = await repo.khoaDeDuyet(client, id);
        if (!sp) throw notFound('Không tìm thấy sản phẩm.');
        if (sp.trangThaiDuyet === d.trangThai && (d.trangThai === 'TU_CHOI' || sp.hangSao === d.hangSao)) {
          throw conflict('TRANG_THAI_KHONG_DOI', 'Sản phẩm đã ở trạng thái này.');
        }
        if (d.trangThai === 'DA_DUYET' && sp.trangThaiNhaCungCap !== 'DA_DUYET') {
          throw conflict('NHA_CUNG_CAP_CHUA_DUYET', 'Cần duyệt nhà cung cấp trước khi duyệt sản phẩm.');
        }
        await repo.capNhatDuyet(client, id, {
          trangThai: d.trangThai,
          hangSao: d.hangSao,
          lyDoTuChoi: d.trangThai === 'TU_CHOI' ? d.lyDo : null,
          nguoiDuyetId,
        });
      });
      return chiTiet(id, { quanTri: true });
    },
  };
};
