'use strict';

const { camel, HOM_NAY_SQL } = require('../../utils/sql');

// Sản phẩm đang bán: chính nó và nhà cung cấp đều đã được duyệt.
const CONG_BO = "sp.trang_thai_duyet = 'DA_DUYET' AND ncc.trang_thai_duyet = 'DA_DUYET'";
// Lô còn bán được: còn hàng và chưa hết hạn sử dụng (theo ngày Việt Nam).
const LO_CON_BAN = `lo.so_luong_con > 0 AND lo.han_su_dung > ${HOM_NAY_SQL}`;

// ---------------------------------------------------------------------------
// Giỏ hàng
// ---------------------------------------------------------------------------

async function gioHang(q, khachId) {
  const { rows } = await q.query(
    `SELECT g.san_pham_id, sp.ten, sp.anh_url, sp.don_vi_tinh, sp.gia, g.so_luong,
            g.so_luong * sp.gia AS thanh_tien,
            (${CONG_BO}) AS dang_ban,
            COALESCE((SELECT sum(lo.so_luong_con) FROM lo_san_xuat lo
                      WHERE lo.san_pham_id = g.san_pham_id AND ${LO_CON_BAN}), 0) AS con_hang
     FROM gio_hang g
     JOIN san_pham sp ON sp.id = g.san_pham_id
     JOIN nha_cung_cap ncc ON ncc.id = sp.nha_cung_cap_id
     WHERE g.nguoi_dung_id = $1
     ORDER BY g.them_luc, g.san_pham_id`,
    [khachId],
  );
  return rows.map(camel);
}

async function sanPhamDangBan(q, sanPhamId) {
  const { rows } = await q.query(
    `SELECT sp.id, sp.ten, sp.gia FROM san_pham sp
     JOIN nha_cung_cap ncc ON ncc.id = sp.nha_cung_cap_id
     WHERE sp.id = $1 AND ${CONG_BO}`,
    [sanPhamId],
  );
  return camel(rows[0]);
}

// Thêm mới hoặc đặt lại số lượng của sản phẩm trong giỏ.
async function datVaoGio(q, khachId, sanPhamId, soLuong) {
  await q.query(
    `INSERT INTO gio_hang (nguoi_dung_id, san_pham_id, so_luong) VALUES ($1, $2, $3)
     ON CONFLICT (nguoi_dung_id, san_pham_id) DO UPDATE SET so_luong = EXCLUDED.so_luong`,
    [khachId, sanPhamId, soLuong],
  );
}

async function xoaKhoiGio(q, khachId, sanPhamIds) {
  const { rowCount } = await q.query(
    'DELETE FROM gio_hang WHERE nguoi_dung_id = $1 AND san_pham_id = ANY($2::int[])',
    [khachId, sanPhamIds],
  );
  return rowCount;
}

// Các dòng trong giỏ, khóa lại để hai lần đặt cùng lúc không đặt trùng một giỏ.
async function khoaGio(q, khachId) {
  const { rows } = await q.query(
    `SELECT san_pham_id, so_luong FROM gio_hang WHERE nguoi_dung_id = $1
     ORDER BY san_pham_id FOR UPDATE`,
    [khachId],
  );
  return rows.map(camel);
}

// ---------------------------------------------------------------------------
// Đặt đơn
// ---------------------------------------------------------------------------

// Sản phẩm đang bán trong danh sách id, kèm giá hiện hành trong CSDL.
async function giaSanPhamDangBan(q, sanPhamIds) {
  const { rows } = await q.query(
    `SELECT sp.id, sp.ten, sp.gia FROM san_pham sp
     JOIN nha_cung_cap ncc ON ncc.id = sp.nha_cung_cap_id
     WHERE sp.id = ANY($1::int[]) AND ${CONG_BO}`,
    [sanPhamIds],
  );
  return rows.map(camel);
}

// Khóa (FOR UPDATE) mọi lô còn bán của các sản phẩm, theo thứ tự id để mọi transaction
// khóa cùng một thứ tự và không gây deadlock. Đơn khác đặt cùng lúc phải chờ transaction
// này xong, rồi đọc lại so_luong_con mới, nên không bán vượt tồn.
async function khoaLoConBan(q, sanPhamIds) {
  const { rows } = await q.query(
    `SELECT lo.id, lo.san_pham_id, lo.ngay_san_xuat, lo.so_luong_con
     FROM lo_san_xuat lo
     WHERE lo.san_pham_id = ANY($1::int[]) AND ${LO_CON_BAN}
     ORDER BY lo.id
     FOR UPDATE`,
    [sanPhamIds],
  );
  return rows.map(camel);
}

async function themDon(q, d) {
  const { rows } = await q.query(
    `INSERT INTO don_hang
       (khach_id, hinh_thuc_giao, phi_giao, tien_hang, tong_tien,
        ten_nguoi_nhan, sdt_nguoi_nhan, dia_chi_giao, ghi_chu)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9) RETURNING id`,
    [d.khachId, d.hinhThucGiao, d.phiGiao, d.tienHang, d.tongTien,
      d.tenNguoiNhan, d.sdtNguoiNhan, d.diaChiGiao, d.ghiChu || null],
  );
  return rows[0].id;
}

async function themChiTiet(q, donId, ct) {
  await q.query(
    `INSERT INTO chi_tiet_don (don_hang_id, san_pham_id, lo_id, so_luong, don_gia)
     VALUES ($1, $2, $3, $4, $5)`,
    [donId, ct.sanPhamId, ct.loId, ct.soLuong, ct.donGia],
  );
}

// Trừ (soLuong > 0) hoặc hoàn (soLuong < 0) tồn của lô. CHECK trong CSDL chặn tồn âm.
async function truTonLo(q, loId, soLuong) {
  await q.query('UPDATE lo_san_xuat SET so_luong_con = so_luong_con - $2 WHERE id = $1', [loId, soLuong]);
}

async function khoaLoTheoId(q, loIds) {
  await q.query('SELECT id FROM lo_san_xuat WHERE id = ANY($1::int[]) ORDER BY id FOR UPDATE', [loIds]);
}

async function themLichSu(q, donId, trangThai, ghiChu, nguoiThucHienId) {
  await q.query(
    `INSERT INTO lich_su_trang_thai_don (don_hang_id, trang_thai, ghi_chu, nguoi_thuc_hien_id)
     VALUES ($1, $2, $3, $4)`,
    [donId, trangThai, ghiChu || null, nguoiThucHienId],
  );
}

// ---------------------------------------------------------------------------
// Xem và xử lý đơn
// ---------------------------------------------------------------------------

// Danh sách đơn. khachId = null: mọi khách (nhân sự xem).
async function dsDon(q, { khachId, trangThai, limit, offset }) {
  const { rows } = await q.query(
    `SELECT dh.id, dh.trang_thai, dh.hinh_thuc_giao, dh.tong_tien, dh.tao_luc, dh.cap_nhat_luc,
            dh.khach_id, nd.ho_ten AS ten_khach, dh.ten_nguoi_nhan,
            ct.so_san_pham, ct.ten_san_pham_dau, ct.anh_san_pham_dau,
            count(*) OVER () AS tong
     FROM don_hang dh
     JOIN nguoi_dung nd ON nd.id = dh.khach_id
     JOIN LATERAL (
       SELECT count(DISTINCT c.san_pham_id) AS so_san_pham,
              (array_agg(sp.ten ORDER BY c.id))[1] AS ten_san_pham_dau,
              (array_agg(sp.anh_url ORDER BY c.id))[1] AS anh_san_pham_dau
       FROM chi_tiet_don c JOIN san_pham sp ON sp.id = c.san_pham_id
       WHERE c.don_hang_id = dh.id
     ) ct ON TRUE
     WHERE ($1::int IS NULL OR dh.khach_id = $1)
       AND ($2::varchar IS NULL OR dh.trang_thai = $2)
     ORDER BY dh.tao_luc DESC, dh.id DESC
     LIMIT $3 OFFSET $4`,
    [khachId ?? null, trangThai ?? null, limit, offset],
  );
  return rows;
}

async function timDon(q, id) {
  const { rows } = await q.query(
    `SELECT dh.id, dh.khach_id, nd.ho_ten AS ten_khach, nd.email AS email_khach,
            dh.trang_thai, dh.hinh_thuc_giao, dh.phi_giao, dh.tien_hang, dh.tong_tien,
            dh.ten_nguoi_nhan, dh.sdt_nguoi_nhan, dh.dia_chi_giao, dh.ghi_chu,
            dh.tao_luc, dh.cap_nhat_luc
     FROM don_hang dh JOIN nguoi_dung nd ON nd.id = dh.khach_id
     WHERE dh.id = $1`,
    [id],
  );
  return camel(rows[0]);
}

// Mỗi dòng là một lô thực tế đã giao: kèm mã truy xuất để khách tra nguồn gốc hàng đã mua.
async function chiTietDon(q, donId) {
  const { rows } = await q.query(
    `SELECT c.san_pham_id, sp.ten AS ten_san_pham, sp.anh_url, sp.don_vi_tinh,
            c.lo_id, lo.ma_truy_xuat, lo.ngay_san_xuat, v.ten AS vung_nguyen_lieu,
            c.so_luong, c.don_gia, c.so_luong * c.don_gia AS thanh_tien,
            EXISTS (SELECT 1 FROM danh_gia dg JOIN don_hang d2 ON d2.id = c.don_hang_id
                    WHERE dg.don_hang_id = c.don_hang_id AND dg.san_pham_id = c.san_pham_id
                      AND dg.khach_id = d2.khach_id) AS da_danh_gia
     FROM chi_tiet_don c
     JOIN san_pham sp ON sp.id = c.san_pham_id
     JOIN lo_san_xuat lo ON lo.id = c.lo_id
     JOIN vung_nguyen_lieu v ON v.id = lo.vung_nguyen_lieu_id
     WHERE c.don_hang_id = $1
     ORDER BY c.id`,
    [donId],
  );
  return rows.map(camel);
}

async function lichSuDon(q, donId) {
  const { rows } = await q.query(
    `SELECT ls.trang_thai, ls.ghi_chu, ls.thoi_diem, nd.ho_ten AS nguoi_thuc_hien
     FROM lich_su_trang_thai_don ls
     LEFT JOIN nguoi_dung nd ON nd.id = ls.nguoi_thuc_hien_id
     WHERE ls.don_hang_id = $1
     ORDER BY ls.thoi_diem, ls.id`,
    [donId],
  );
  return rows.map(camel);
}

async function khoaDon(q, id) {
  const { rows } = await q.query('SELECT id, khach_id, trang_thai FROM don_hang WHERE id = $1 FOR UPDATE', [id]);
  return camel(rows[0]);
}

async function capNhatTrangThai(q, id, trangThai) {
  await q.query('UPDATE don_hang SET trang_thai = $2, cap_nhat_luc = now() WHERE id = $1', [id, trangThai]);
}

async function soLuongTheoLo(q, donId) {
  const { rows } = await q.query(
    'SELECT lo_id, so_luong FROM chi_tiet_don WHERE don_hang_id = $1 ORDER BY lo_id',
    [donId],
  );
  return rows.map(camel);
}

module.exports = {
  gioHang, sanPhamDangBan, datVaoGio, xoaKhoiGio, khoaGio,
  giaSanPhamDangBan, khoaLoConBan, themDon, themChiTiet, truTonLo, khoaLoTheoId, themLichSu,
  dsDon, timDon, chiTietDon, lichSuDon, khoaDon, capNhatTrangThai, soLuongTheoLo,
};
