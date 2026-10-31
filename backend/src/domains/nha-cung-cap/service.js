'use strict';

// Tầng service: quy tắc nghiệp vụ và transaction của miền nhà cung cấp.
const repo = require('./repo');
const { notFound, conflict, badRequest } = require('../../utils/errors');
const { ketQuaPhanTrang } = require('../../utils/sql');

module.exports = function createNhaCungCapService({ db }) {
  async function chiTietQuanTri(id) {
    const ncc = await repo.timQuanTri(db, id);
    if (!ncc) throw notFound('Không tìm thấy nhà cung cấp.');
    return { ...ncc, chungNhan: await repo.dsChungNhan(db, id) };
  }

  return {
    // Dùng chung cho miền sản phẩm và truy xuất (được truyền vào qua app wiring).
    dsChungNhan: (nhaCungCapId) => repo.dsChungNhan(db, nhaCungCapId),

    dsCongKhai: ({ vung }) => repo.dsDaDuyet(db, vung),

    async chiTietCongKhai(id) {
      const ncc = await repo.timDaDuyet(db, id);
      if (!ncc) throw notFound('Không tìm thấy nhà cung cấp.');
      const [chungNhan, sanPham] = await Promise.all([repo.dsChungNhan(db, id), repo.sanPhamDaDuyet(db, id)]);
      return { ...ncc, chungNhan, sanPham };
    },

    async dsQuanTri(loc, p) {
      const rows = await repo.dsQuanTri(db, { ...loc, limit: p.kichThuoc, offset: p.offset });
      return ketQuaPhanTrang(rows, p);
    },

    chiTietQuanTri,

    // Hồ sơ và mọi chứng nhận cùng được lưu trong một transaction, hoặc không lưu gì nếu lỗi.
    async taoHoSo(d, nguoiTaoId) {
      const id = await db.withTransaction(async (client) => {
        if (!(await repo.vungTonTai(client, d.vungId))) {
          throw badRequest('Vùng nguyên liệu không tồn tại.', [{ truong: 'vungId', thongDiep: 'Không tồn tại.' }]);
        }
        const nccId = await repo.themNhaCungCap(client, d, nguoiTaoId);
        for (const cn of d.chungNhan) await repo.themChungNhan(client, nccId, cn);
        return nccId;
      }).catch((err) => {
        if (err.code === '23505' && err.constraint === 'chung_nhan_loai_so_hieu_key') {
          throw conflict('CHUNG_NHAN_TRUNG', 'Số hiệu chứng nhận đã tồn tại.');
        }
        throw err;
      });
      return chiTietQuanTri(id);
    },

    // Duyệt cần ảnh cơ sở và chứng nhận OCOP còn hiệu lực; từ chối cần lý do.
    async duyet(id, d, nguoiDuyetId) {
      await db.withTransaction(async (client) => {
        const ncc = await repo.khoaDeDuyet(client, id);
        if (!ncc) throw notFound('Không tìm thấy nhà cung cấp.');
        if (ncc.trangThaiDuyet === d.trangThai) {
          throw conflict('TRANG_THAI_KHONG_DOI', 'Hồ sơ đã ở trạng thái này.');
        }
        if (d.trangThai === 'DA_DUYET') {
          if (!ncc.anhCoSoUrl) throw conflict('THIEU_ANH_CO_SO', 'Hồ sơ chưa có ảnh cơ sở sản xuất.');
          if (!(await repo.coChungNhanOcopHieuLuc(client, id))) {
            throw conflict('THIEU_CHUNG_NHAN_OCOP', 'Hồ sơ chưa có chứng nhận OCOP còn hiệu lực.');
          }
        }
        await repo.capNhatDuyet(client, id, {
          trangThai: d.trangThai,
          lyDoTuChoi: d.trangThai === 'TU_CHOI' ? d.lyDo : null,
          nguoiDuyetId,
        });
      });
      return chiTietQuanTri(id);
    },
  };
};
