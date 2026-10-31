'use strict';

const express = require('express');
const { notFound } = require('../errors');
const { ah, camel, MA_TRUY_XUAT_REGEX } = require('../utils');
const { HOM_NAY } = require('./nhaCungCap');

// GET /truy-xuat/:maTruyXuat — CÔNG KHAI, không cần JWT.
// Trả hành trình của đúng lô có mã này. Chỉ trả thông tin cần cho truy xuất: không có
// số lượng tồn, ghi chú nội bộ, người nhập liệu, đơn hàng hay thông tin người mua.
// Lô chỉ được công bố khi sản phẩm và nhà cung cấp đang ở trạng thái đã duyệt; nếu
// không, trả 404 để app báo "không xác minh được nguồn gốc".
module.exports = function truyXuatRouter({ pool }) {
  const r = express.Router();

  r.get('/:ma', ah(async (req, res) => {
    const ma = String(req.params.ma).trim().toUpperCase();
    const khongThay = notFound('Không tìm thấy lô với mã truy xuất này hoặc lô chưa được công bố.');
    if (!MA_TRUY_XUAT_REGEX.test(ma)) throw khongThay;

    const { rows } = await pool.query(
      `SELECT lo.id AS lo_id, lo.ma_truy_xuat, lo.ngay_san_xuat, lo.han_su_dung,
              lo.nguoi_san_xuat, lo.anh_hien_truong_url,
              vl.id AS vung_lo_id, vl.ten AS vung_lo_ten, vl.mo_ta AS vung_lo_mo_ta,
              vl.vi_do AS vung_lo_vi_do, vl.kinh_do AS vung_lo_kinh_do,
              sp.id AS sp_id, sp.ten AS sp_ten, sp.mo_ta AS sp_mo_ta, sp.don_vi_tinh AS sp_don_vi_tinh,
              sp.hang_sao AS sp_hang_sao, sp.anh_url AS sp_anh_url,
              ncc.id AS ncc_id, ncc.ten AS ncc_ten, ncc.dia_chi AS ncc_dia_chi,
              ncc.anh_co_so_url AS ncc_anh_co_so_url, vn.ten AS ncc_vung
       FROM lo_san_xuat lo
       JOIN san_pham sp ON sp.id = lo.san_pham_id
       JOIN nha_cung_cap ncc ON ncc.id = sp.nha_cung_cap_id
       JOIN vung_nguyen_lieu vl ON vl.id = lo.vung_nguyen_lieu_id
       JOIN vung_nguyen_lieu vn ON vn.id = ncc.vung_id
       WHERE lo.ma_truy_xuat = $1
         AND sp.trang_thai_duyet = 'DA_DUYET' AND ncc.trang_thai_duyet = 'DA_DUYET'`,
      [ma],
    );
    const x = rows[0];
    if (!x) throw khongThay;

    const [buoc, chungNhan] = await Promise.all([
      pool.query(
        `SELECT thu_tu, ten_buoc, mo_ta, thoi_diem, anh_url
         FROM buoc_truy_xuat WHERE lo_id = $1 ORDER BY thu_tu`,
        [x.lo_id],
      ),
      pool.query(
        `SELECT loai, so_hieu, ngay_cap, ngay_het_han, anh_url,
                (ngay_het_han IS NULL OR ngay_het_han >= ${HOM_NAY}) AS con_hieu_luc
         FROM chung_nhan WHERE nha_cung_cap_id = $1 ORDER BY loai`,
        [x.ncc_id],
      ),
    ]);

    res.json({
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
        chungNhan: chungNhan.rows.map(camel),
      },
      cacBuoc: buoc.rows.map(camel),
    });
  }));

  return r;
};
