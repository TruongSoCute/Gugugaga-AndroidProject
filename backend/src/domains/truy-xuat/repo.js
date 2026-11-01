'use strict';

const { camel } = require('../../utils/sql');

async function dsLo(q, { sanPhamId, limit, offset }) {
  const { rows } = await q.query(
    `SELECT lo.id, lo.ma_truy_xuat, lo.san_pham_id, sp.ten AS ten_san_pham,
            lo.ngay_san_xuat, lo.han_su_dung, lo.so_luong, lo.so_luong_con,
            v.ten AS ten_vung, lo.nguoi_san_xuat,
            (SELECT count(*) FROM buoc_truy_xuat b WHERE b.lo_id = lo.id) AS so_buoc,
            count(*) OVER () AS tong
     FROM lo_san_xuat lo
     JOIN san_pham sp ON sp.id = lo.san_pham_id
     JOIN vung_nguyen_lieu v ON v.id = lo.vung_nguyen_lieu_id
     WHERE ($1::int IS NULL OR lo.san_pham_id = $1)
     ORDER BY lo.tao_luc DESC, lo.id DESC
     LIMIT $2 OFFSET $3`,
    [sanPhamId ?? null, limit, offset],
  );
  return rows;
}

async function timLo(q, id) {
  const { rows } = await q.query(
    `SELECT lo.id, lo.ma_truy_xuat, lo.san_pham_id, sp.ten AS ten_san_pham,
            sp.trang_thai_duyet AS trang_thai_san_pham,
            lo.ngay_san_xuat, lo.han_su_dung, lo.so_luong, lo.so_luong_con,
            lo.vung_nguyen_lieu_id, v.ten AS ten_vung, lo.nguoi_san_xuat,
            lo.anh_hien_truong_url, lo.ghi_chu, lo.tao_luc
     FROM lo_san_xuat lo
     JOIN san_pham sp ON sp.id = lo.san_pham_id
     JOIN vung_nguyen_lieu v ON v.id = lo.vung_nguyen_lieu_id
     WHERE lo.id = $1`,
    [id],
  );
  return camel(rows[0]);
}

async function cacBuoc(q, loId) {
  const { rows } = await q.query(
    `SELECT id, thu_tu, ten_buoc, mo_ta, thoi_diem, anh_url
     FROM buoc_truy_xuat WHERE lo_id = $1 ORDER BY thu_tu`,
    [loId],
  );
  return rows.map(camel);
}

// Trạng thái sản phẩm và vùng mặc định (vùng của nhà cung cấp) khi tạo lô.
async function sanPhamChoLo(q, sanPhamId) {
  const { rows } = await q.query(
    `SELECT sp.trang_thai_duyet, ncc.vung_id
     FROM san_pham sp JOIN nha_cung_cap ncc ON ncc.id = sp.nha_cung_cap_id
     WHERE sp.id = $1`,
    [sanPhamId],
  );
  return camel(rows[0]);
}

async function vungTonTai(q, vungId) {
  const { rowCount } = await q.query('SELECT 1 FROM vung_nguyen_lieu WHERE id = $1', [vungId]);
  return rowCount > 0;
}

// Số lượng còn bán ban đầu bằng số lượng của lô.
async function themLo(q, d) {
  const { rows } = await q.query(
    `INSERT INTO lo_san_xuat
       (san_pham_id, ma_truy_xuat, ngay_san_xuat, han_su_dung, so_luong, so_luong_con,
        vung_nguyen_lieu_id, nguoi_san_xuat, anh_hien_truong_url, ghi_chu, nguoi_tao_id)
     VALUES ($1, $2, $3, $4, $5, $5, $6, $7, $8, $9, $10) RETURNING id`,
    [d.sanPhamId, d.maTruyXuat, d.ngaySanXuat, d.hanSuDung, d.soLuong, d.vungNguyenLieuId,
      d.nguoiSanXuat, d.anhHienTruongUrl || null, d.ghiChu || null, d.nguoiTaoId],
  );
  return rows[0].id;
}

async function themBuoc(q, loId, b) {
  await q.query(
    `INSERT INTO buoc_truy_xuat (lo_id, thu_tu, ten_buoc, mo_ta, thoi_diem, anh_url)
     VALUES ($1, $2, $3, $4, $5, $6)`,
    [loId, b.thuTu, b.tenBuoc, b.moTa || null, b.thoiDiem, b.anhUrl || null],
  );
}

async function loTonTai(q, loId) {
  const { rowCount } = await q.query('SELECT 1 FROM lo_san_xuat WHERE id = $1', [loId]);
  return rowCount > 0;
}

// Thêm bước; không có thuTu thì lấy thứ tự kế tiếp trong cùng câu lệnh.
async function themBuocTuDongThuTu(q, loId, b) {
  const { rows } = await q.query(
    `INSERT INTO buoc_truy_xuat (lo_id, thu_tu, ten_buoc, mo_ta, thoi_diem, anh_url)
     SELECT $1, COALESCE($2::smallint, COALESCE(max(thu_tu), 0) + 1), $3, $4, $5, $6
     FROM buoc_truy_xuat WHERE lo_id = $1
     RETURNING id, thu_tu, ten_buoc, mo_ta, thoi_diem, anh_url`,
    [loId, b.thuTu ?? null, b.tenBuoc, b.moTa || null, b.thoiDiem, b.anhUrl || null],
  );
  return camel(rows[0]);
}

// Truy xuất công khai: chỉ lô của sản phẩm VÀ nhà cung cấp đang được duyệt.
async function timLoCongKhai(q, ma) {
  const { rows } = await q.query(
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
  return rows[0];
}

module.exports = {
  dsLo, timLo, cacBuoc, sanPhamChoLo, vungTonTai, themLo, themBuoc, loTonTai,
  themBuocTuDongThuTu, timLoCongKhai,
};
