'use strict';

// Tầng service: quy tắc nghiệp vụ và transaction của miền nhà cung cấp.
const repo = require('./repo');
const { notFound, conflict, badRequest, HttpError } = require('../../utils/errors');
const { ketQuaPhanTrang } = require('../../utils/sql');

const doiLoiChungNhanTrung = (err) => {
  if (err.code === '23505' && err.constraint === 'chung_nhan_loai_so_hieu_key') {
    throw conflict('CHUNG_NHAN_TRUNG', 'Số hiệu chứng nhận đã tồn tại.');
  }
  throw err;
};

module.exports = function createNhaCungCapService({ db }) {
  async function kiemTraVung(client, vungId) {
    if (!(await repo.vungTonTai(client, vungId))) {
      throw badRequest('Vùng nguyên liệu không tồn tại.', [{ truong: 'vungId', thongDiep: 'Không tồn tại.' }]);
    }
  }

  // Lưu hồ sơ + chứng nhận trong một transaction. taiKhoanId: chủ hồ sơ (null nếu nhân sự nhập).
  function luuHoSoMoi(d, nguoiTaoId, taiKhoanId) {
    return db.withTransaction(async (client) => {
      await kiemTraVung(client, d.vungId);
      const nccId = await repo.themNhaCungCap(client, d, nguoiTaoId, taiKhoanId);
      for (const cn of d.chungNhan) await repo.themChungNhan(client, nccId, cn);
      return nccId;
    }).catch(doiLoiChungNhanTrung);
  }

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
      return chiTietQuanTri(await luuHoSoMoi(d, nguoiTaoId, null));
    },

    // ---- Nhà cung cấp tự quản lý hồ sơ của mình (app Client) ----

    // Id và trạng thái hồ sơ của tài khoản; null nếu chưa gửi hồ sơ. Miền sản phẩm dùng qua wiring.
    hoSoCuaTaiKhoan: (taiKhoanId) => repo.timTheoTaiKhoan(db, taiKhoanId),

    async hoSoCuaToi(taiKhoanId) {
      const hs = await repo.timTheoTaiKhoan(db, taiKhoanId);
      if (!hs) throw new HttpError(404, 'CHUA_CO_HO_SO', 'Tài khoản chưa gửi hồ sơ nhà cung cấp.');
      return chiTietQuanTri(hs.id);
    },

    // Mỗi tài khoản chỉ có một hồ sơ; hồ sơ mới luôn CHO_DUYET.
    async taoHoSoCuaToi(taiKhoanId, d) {
      if (await repo.timTheoTaiKhoan(db, taiKhoanId)) {
        throw conflict('DA_CO_HO_SO', 'Tài khoản đã có hồ sơ nhà cung cấp; hãy sửa hồ sơ hiện có.');
      }
      return chiTietQuanTri(await luuHoSoMoi(d, taiKhoanId, taiKhoanId));
    },

    // Sửa hồ sơ chờ duyệt hoặc bị từ chối: thay toàn bộ chứng nhận và đưa về CHO_DUYET (gửi duyệt lại).
    // Hồ sơ đã duyệt không tự sửa được, vì sản phẩm của nó đang được bán công khai.
    async capNhatHoSoCuaToi(taiKhoanId, d) {
      const id = await db.withTransaction(async (client) => {
        const hs = await repo.timTheoTaiKhoan(client, taiKhoanId, { khoa: true });
        if (!hs) throw new HttpError(404, 'CHUA_CO_HO_SO', 'Tài khoản chưa gửi hồ sơ nhà cung cấp.');
        if (hs.trangThaiDuyet === 'DA_DUYET') {
          throw conflict('HO_SO_DA_DUYET', 'Hồ sơ đã được duyệt; liên hệ quản trị để thay đổi thông tin.');
        }
        await kiemTraVung(client, d.vungId);
        await repo.capNhatHoSoChoDuyetLai(client, hs.id, d);
        await repo.xoaChungNhan(client, hs.id);
        for (const cn of d.chungNhan) await repo.themChungNhan(client, hs.id, cn);
        return hs.id;
      }).catch(doiLoiChungNhanTrung);
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
