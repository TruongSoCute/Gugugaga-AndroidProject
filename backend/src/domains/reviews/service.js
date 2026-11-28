'use strict';

const repo = require('./repo');
const { HttpError, notFound, conflict } = require('../../utils/errors');
const { ketQuaPhanTrang } = require('../../utils/sql');

module.exports = function createDanhGiaService({ db }) {
  return {
    // Khách chỉ đánh giá sản phẩm có trong đơn của mình và đơn đã nhận (DA_NHAN);
    // mỗi sản phẩm trong một đơn đánh giá một lần. Đánh giá và ảnh lưu trong một transaction.
    async danhGia(khachId, d) {
      const id = await db.withTransaction(async (client) => {
        const don = await repo.donChuaSanPham(client, { ...d, khachId });
        if (!don) throw notFound('Không tìm thấy đơn hàng.');
        if (!don.coSanPham) {
          throw new HttpError(400, 'DU_LIEU_KHONG_HOP_LE', 'Dữ liệu không hợp lệ.',
            [{ truong: 'sanPhamId', thongDiep: 'Sản phẩm không có trong đơn hàng này.' }]);
        }
        if (don.trangThai !== 'DA_NHAN') {
          throw conflict('DON_CHUA_NHAN', 'Chỉ đánh giá được sau khi xác nhận đã nhận hàng.');
        }
        const danhGiaId = await repo.themDanhGia(client, { ...d, khachId });
        for (const url of d.anhUrls) await repo.themAnh(client, danhGiaId, url);
        return danhGiaId;
      }).catch((err) => {
        if (err.code === '23505') throw conflict('DA_DANH_GIA', 'Bạn đã đánh giá sản phẩm này trong đơn hàng này.');
        throw err;
      });
      return repo.timTheoId(db, id);
    },

    async dsTheoSanPham(sanPhamId, p) {
      const [rows, tong] = await Promise.all([
        repo.dsTheoSanPham(db, sanPhamId, { limit: p.kichThuoc, offset: p.offset }),
        repo.tongHop(db, sanPhamId),
      ]);
      return { ...ketQuaPhanTrang(rows, p), tongHop: tong };
    },
  };
};
