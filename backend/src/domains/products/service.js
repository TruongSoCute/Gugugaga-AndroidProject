'use strict';

const repo = require('./repo');
const { notFound, conflict, badRequest, HttpError } = require('../../utils/errors');
const { ketQuaPhanTrang } = require('../../utils/sql');

// deps.nhaCungCap: service của miền nhà cung cấp, truyền vào từ app wiring
// (miền này không import trực tiếp miền khác).
module.exports = function createSanPhamService({ db }, { nhaCungCap }) {
  // Hồ sơ nhà cung cấp của tài khoản đang đăng nhập; chưa có hồ sơ thì chưa thêm được sản phẩm.
  async function hoSoCuaToi(taiKhoanId) {
    const hs = await nhaCungCap.hoSoCuaTaiKhoan(taiKhoanId);
    if (!hs) throw new HttpError(409, 'CHUA_CO_HO_SO', 'Cần gửi hồ sơ nhà cung cấp trước khi thêm sản phẩm.');
    return hs;
  }

  async function chiTietCuaToi(taiKhoanId, id) {
    const hs = await hoSoCuaToi(taiKhoanId);
    const sp = await repo.timCuaNhaCungCap(db, id, hs.id);
    if (!sp) throw notFound('Không tìm thấy sản phẩm của bạn.');
    return sp;
  }

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

    // ---- Nhà cung cấp tự quản lý sản phẩm (app Client) ----
    async dsCuaToi(taiKhoanId) {
      const hs = await nhaCungCap.hoSoCuaTaiKhoan(taiKhoanId);
      return hs ? repo.dsCuaNhaCungCap(db, hs.id) : [];
    },

    chiTietCuaToi,

    // Sản phẩm mới luôn CHO_DUYET; hồ sơ bị từ chối thì không thêm được (giống nhân sự nhập).
    async taoCuaToi(taiKhoanId, d) {
      const hs = await hoSoCuaToi(taiKhoanId);
      if (hs.trangThaiDuyet === 'TU_CHOI') {
        throw conflict('NHA_CUNG_CAP_BI_TU_CHOI', 'Hồ sơ đang bị từ chối; hãy sửa hồ sơ và gửi duyệt lại trước.');
      }
      const id = await repo.them(db, { ...d, nhaCungCapId: hs.id }, taiKhoanId);
      return chiTietCuaToi(taiKhoanId, id);
    },

    // Chỉ sửa được sản phẩm chờ duyệt hoặc bị từ chối; sửa xong quay về CHO_DUYET.
    async capNhatCuaToi(taiKhoanId, id, d) {
      const hs = await hoSoCuaToi(taiKhoanId);
      await db.withTransaction(async (client) => {
        const sp = await repo.timCuaNhaCungCap(client, id, hs.id, { khoa: true });
        if (!sp) throw notFound('Không tìm thấy sản phẩm của bạn.');
        if (sp.trangThaiDuyet === 'DA_DUYET') {
          throw conflict('SAN_PHAM_DA_DUYET', 'Sản phẩm đã được duyệt và đang bán; liên hệ quản trị để thay đổi.');
        }
        await repo.capNhatChoDuyetLai(client, id, d);
      });
      return chiTietCuaToi(taiKhoanId, id);
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
