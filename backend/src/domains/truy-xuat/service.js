'use strict';

const repo = require('./repo');
const { MA_TRUY_XUAT_SO_BYTE } = require('./types');
const { notFound, conflict, badRequest } = require('../../utils/errors');
const { ketQuaPhanTrang } = require('../../utils/sql');

const SO_LAN_THU_SINH_MA = 3;

// deps.nhaCungCap: service miền nhà cung cấp (lấy chứng nhận), truyền vào từ app wiring.
module.exports = function createTruyXuatService({ db, random }, { nhaCungCap }) {
  async function chiTietLo(id) {
    const lo = await repo.timLo(db, id);
    if (!lo) throw notFound('Không tìm thấy lô.');
    return { ...lo, cacBuoc: await repo.cacBuoc(db, id) };
  }

  async function taoLoMotLan(d, nguoiTaoId) {
    return db.withTransaction(async (client) => {
      const sp = await repo.sanPhamChoLo(client, d.sanPhamId);
      if (!sp) {
        throw badRequest('Dữ liệu không hợp lệ.', [{ truong: 'sanPhamId', thongDiep: 'Sản phẩm không tồn tại.' }]);
      }
      if (sp.trangThaiDuyet === 'TU_CHOI') {
        throw conflict('SAN_PHAM_BI_TU_CHOI', 'Sản phẩm đã bị từ chối, không thể tạo lô.');
      }
      const vungNguyenLieuId = d.vungNguyenLieuId ?? sp.vungId;
      if (!(await repo.vungTonTai(client, vungNguyenLieuId))) {
        throw badRequest('Dữ liệu không hợp lệ.', [{ truong: 'vungNguyenLieuId', thongDiep: 'Vùng không tồn tại.' }]);
      }
      const loId = await repo.themLo(client, {
        ...d, vungNguyenLieuId, nguoiTaoId, maTruyXuat: random.hexUpper(MA_TRUY_XUAT_SO_BYTE),
      });
      for (const b of d.cacBuoc) await repo.themBuoc(client, loId, b);
      return loId;
    });
  }

  return {
    async dsLo(loc, p) {
      const rows = await repo.dsLo(db, { ...loc, limit: p.kichThuoc, offset: p.offset });
      return ketQuaPhanTrang(rows, p);
    },

    chiTietLo,

    // Lô và các bước được lưu trong một transaction. Mã truy xuất do server sinh;
    // xác suất trùng mã 80 bit gần như bằng 0, nếu vẫn trùng thì sinh mã khác và thử lại.
    async taoLo(d, nguoiTaoId) {
      for (let lan = 1; ; lan += 1) {
        try {
          return chiTietLo(await taoLoMotLan(d, nguoiTaoId));
        } catch (err) {
          const trungMa = err.code === '23505' && err.constraint === 'lo_san_xuat_ma_truy_xuat_key';
          if (!trungMa || lan >= SO_LAN_THU_SINH_MA) throw err;
        }
      }
    },

    async themBuoc(loId, b) {
      if (!(await repo.loTonTai(db, loId))) throw notFound('Không tìm thấy lô.');
      try {
        return await repo.themBuocTuDongThuTu(db, loId, b);
      } catch (err) {
        if (err.code === '23505') throw conflict('THU_TU_BUOC_TRUNG', 'Lô đã có bước với thứ tự này.');
        throw err;
      }
    },

    // Hành trình công khai của đúng một lô. ma = null (sai định dạng) cũng trả 404.
    // Chỉ chứa thông tin cần cho truy xuất: không có id lô, tồn kho, ghi chú nội bộ,
    // người nhập liệu, số điện thoại hay người đại diện.
    async truyXuatCongKhai(ma) {
      const khongThay = notFound('Không tìm thấy lô với mã truy xuất này hoặc lô chưa được công bố.');
      if (!ma) throw khongThay;
      const x = await repo.timLoCongKhai(db, ma);
      if (!x) throw khongThay;

      const [buoc, chungNhan] = await Promise.all([repo.cacBuoc(db, x.lo_id), nhaCungCap.dsChungNhan(x.ncc_id)]);
      return {
        maTruyXuat: x.ma_truy_xuat,
        lo: {
          ngaySanXuat: x.ngay_san_xuat,
          hanSuDung: x.han_su_dung,
          nguoiSanXuat: x.nguoi_san_xuat,
          anhHienTruongUrl: x.anh_hien_truong_url,
          vungNguyenLieu: {
            id: x.vung_lo_id, ten: x.vung_lo_ten, moTa: x.vung_lo_mo_ta,
            viDo: x.vung_lo_vi_do, kinhDo: x.vung_lo_kinh_do,
          },
        },
        sanPham: {
          id: x.sp_id, ten: x.sp_ten, moTa: x.sp_mo_ta, donViTinh: x.sp_don_vi_tinh,
          hangSao: x.sp_hang_sao, anhUrl: x.sp_anh_url,
        },
        nhaCungCap: {
          id: x.ncc_id, ten: x.ncc_ten, diaChi: x.ncc_dia_chi,
          anhCoSoUrl: x.ncc_anh_co_so_url, vung: x.ncc_vung,
          chungNhan: chungNhan.map(({ id, ...cn }) => cn),
        },
        cacBuoc: buoc.map(({ id, ...b }) => b),
      };
    },
  };
};
