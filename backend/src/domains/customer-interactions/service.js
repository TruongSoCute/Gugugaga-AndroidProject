'use strict';

const repo = require('./repo');
const { notFound } = require('../../utils/errors');

// Yêu thích sản phẩm và theo dõi nhà cung cấp. Thêm/bỏ là idempotent: gọi lại không lỗi.
module.exports = function createTuongTacService({ db }) {
  return {
    dsYeuThich: (id) => repo.dsYeuThich(db, id),

    async yeuThich(nguoiDungId, sanPhamId) {
      if (!(await repo.sanPhamCongBo(db, sanPhamId))) throw notFound('Không tìm thấy sản phẩm đang bán.');
      await repo.themYeuThich(db, nguoiDungId, sanPhamId);
      return { sanPhamId, yeuThich: true };
    },

    async boYeuThich(nguoiDungId, sanPhamId) {
      await repo.boYeuThich(db, nguoiDungId, sanPhamId);
      return { sanPhamId, yeuThich: false };
    },

    dsTheoDoi: (id) => repo.dsTheoDoi(db, id),

    async theoDoi(nguoiDungId, nccId) {
      if (!(await repo.nhaCungCapDaDuyet(db, nccId))) throw notFound('Không tìm thấy nhà cung cấp.');
      await repo.themTheoDoi(db, nguoiDungId, nccId);
      return { nhaCungCapId: nccId, theoDoi: true };
    },

    async boTheoDoi(nguoiDungId, nccId) {
      await repo.boTheoDoi(db, nguoiDungId, nccId);
      return { nhaCungCapId: nccId, theoDoi: false };
    },
  };
};
