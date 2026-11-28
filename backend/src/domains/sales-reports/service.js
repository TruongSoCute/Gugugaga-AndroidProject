'use strict';

const repo = require('./repo');
const { TRANG_THAI_TINH_DOANH_SO, SO_NHA_CUNG_CAP_TOP } = require('./types');

module.exports = function createBaoCaoService({ db }) {
  return {
    // Doanh số theo vùng nguyên liệu (của lô thực tế đã giao), theo hạng sao và nhà cung cấp bán chạy.
    async doanhSo(loc) {
      const ts = [...TRANG_THAI_TINH_DOANH_SO];
      const [tong, theoVung, theoHangSao, nhaCungCapBanChay] = await Promise.all([
        repo.tong(db, loc, ts),
        repo.theoVung(db, loc, ts),
        repo.theoHangSao(db, loc, ts),
        repo.nhaCungCapBanChay(db, loc, ts, SO_NHA_CUNG_CAP_TOP),
      ]);
      return {
        boLoc: { tu: loc.tu ?? null, den: loc.den ?? null, vung: loc.vung ?? null, trangThaiTinh: ts },
        tong, theoVung, theoHangSao, nhaCungCapBanChay,
      };
    },
  };
};
