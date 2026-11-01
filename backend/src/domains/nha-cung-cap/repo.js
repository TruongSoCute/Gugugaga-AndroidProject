'use strict';

// Tầng repo: chỉ chứa câu SQL tham số hóa ($1, $2...). Tham số đầu `q` là pool
// hoặc client của transaction, do tầng service truyền vào.
const { camel, HOM_NAY_SQL } = require('../../utils/sql');

const COT = `ncc.id, ncc.ten, ncc.nguoi_dai_dien, ncc.so_dien_thoai, ncc.dia_chi,
  ncc.vung_id, v.ten AS ten_vung, ncc.anh_co_so_url, ncc.trang_thai_duyet`;
const SO_NGUOI_THEO_DOI = `(SELECT count(*) FROM theo_doi_nha_cung_cap t
  WHERE t.nha_cung_cap_id = ncc.id) AS so_nguoi_theo_doi`;

async function dsDaDuyet(q, vungId) {
  const { rows } = await q.query(
    `SELECT ${COT}, ${SO_NGUOI_THEO_DOI}
     FROM nha_cung_cap ncc JOIN vung_nguyen_lieu v ON v.id = ncc.vung_id
     WHERE ncc.trang_thai_duyet = 'DA_DUYET' AND ($1::int IS NULL OR ncc.vung_id = $1)
     ORDER BY ncc.ten`,
    [vungId ?? null],
  );
  return rows.map(camel);
}

async function timDaDuyet(q, id) {
  const { rows } = await q.query(
    `SELECT ${COT}, ${SO_NGUOI_THEO_DOI}
     FROM nha_cung_cap ncc JOIN vung_nguyen_lieu v ON v.id = ncc.vung_id
     WHERE ncc.id = $1 AND ncc.trang_thai_duyet = 'DA_DUYET'`,
    [id],
  );
  return camel(rows[0]);
}

async function sanPhamDaDuyet(q, nhaCungCapId) {
  const { rows } = await q.query(
    `SELECT id, ten, gia, don_vi_tinh, hang_sao, anh_url FROM san_pham
     WHERE nha_cung_cap_id = $1 AND trang_thai_duyet = 'DA_DUYET' ORDER BY ten`,
    [nhaCungCapId],
  );
  return rows.map(camel);
}

async function dsChungNhan(q, nhaCungCapId) {
  const { rows } = await q.query(
    `SELECT id, loai, so_hieu, ngay_cap, ngay_het_han, anh_url,
            (ngay_het_han IS NULL OR ngay_het_han >= ${HOM_NAY_SQL}) AS con_hieu_luc
     FROM chung_nhan WHERE nha_cung_cap_id = $1 ORDER BY loai, ngay_cap`,
    [nhaCungCapId],
  );
  return rows.map(camel);
}

// Danh sách cho app Admin: mọi trạng thái, hồ sơ chờ duyệt xếp trước. Có cột "tong".
async function dsQuanTri(q, { trangThai, vung, limit, offset }) {
  const { rows } = await q.query(
    `SELECT ${COT}, ncc.ly_do_tu_choi, ncc.tao_luc, (ncc.tai_khoan_id IS NOT NULL) AS tu_gui,
            count(*) OVER () AS tong
     FROM nha_cung_cap ncc JOIN vung_nguyen_lieu v ON v.id = ncc.vung_id
     WHERE ($1::text IS NULL OR ncc.trang_thai_duyet = $1)
       AND ($2::int IS NULL OR ncc.vung_id = $2)
     ORDER BY (ncc.trang_thai_duyet = 'CHO_DUYET') DESC, ncc.tao_luc DESC
     LIMIT $3 OFFSET $4`,
    [trangThai ?? null, vung ?? null, limit, offset],
  );
  return rows;
}

async function timQuanTri(q, id) {
  const { rows } = await q.query(
    `SELECT ${COT}, ncc.ly_do_tu_choi, ncc.duyet_luc, ncc.tao_luc, nd.ho_ten AS nguoi_duyet,
            (ncc.tai_khoan_id IS NOT NULL) AS tu_gui
     FROM nha_cung_cap ncc
     JOIN vung_nguyen_lieu v ON v.id = ncc.vung_id
     LEFT JOIN nguoi_dung nd ON nd.id = ncc.nguoi_duyet_id
     WHERE ncc.id = $1`,
    [id],
  );
  return camel(rows[0]);
}

async function vungTonTai(q, vungId) {
  const { rowCount } = await q.query('SELECT 1 FROM vung_nguyen_lieu WHERE id = $1', [vungId]);
  return rowCount > 0;
}

// taiKhoanId: tài khoản NHA_CUNG_CAP sở hữu hồ sơ (null khi nhân sự nhập hộ).
async function themNhaCungCap(q, d, nguoiTaoId, taiKhoanId = null) {
  const { rows } = await q.query(
    `INSERT INTO nha_cung_cap
       (ten, nguoi_dai_dien, so_dien_thoai, dia_chi, vung_id, anh_co_so_url, nguoi_tao_id, tai_khoan_id)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING id`,
    [d.ten, d.nguoiDaiDien, d.soDienThoai, d.diaChi, d.vungId, d.anhCoSoUrl || null, nguoiTaoId, taiKhoanId],
  );
  return rows[0].id;
}

// Hồ sơ của một tài khoản nhà cung cấp. khoa = true: khóa dòng để sửa trong transaction.
async function timTheoTaiKhoan(q, taiKhoanId, { khoa = false } = {}) {
  const { rows } = await q.query(
    `SELECT id, trang_thai_duyet FROM nha_cung_cap WHERE tai_khoan_id = $1${khoa ? ' FOR UPDATE' : ''}`,
    [taiKhoanId],
  );
  return camel(rows[0]);
}

// Nhà cung cấp sửa hồ sơ: đưa về CHO_DUYET để quản trị duyệt lại, xóa kết quả duyệt cũ.
async function capNhatHoSoChoDuyetLai(q, id, d) {
  await q.query(
    `UPDATE nha_cung_cap
     SET ten = $2, nguoi_dai_dien = $3, so_dien_thoai = $4, dia_chi = $5, vung_id = $6, anh_co_so_url = $7,
         trang_thai_duyet = 'CHO_DUYET', ly_do_tu_choi = NULL, nguoi_duyet_id = NULL, duyet_luc = NULL
     WHERE id = $1`,
    [id, d.ten, d.nguoiDaiDien, d.soDienThoai, d.diaChi, d.vungId, d.anhCoSoUrl || null],
  );
}

async function xoaChungNhan(q, nhaCungCapId) {
  await q.query('DELETE FROM chung_nhan WHERE nha_cung_cap_id = $1', [nhaCungCapId]);
}

async function themChungNhan(q, nhaCungCapId, cn) {
  await q.query(
    `INSERT INTO chung_nhan (nha_cung_cap_id, loai, so_hieu, ngay_cap, ngay_het_han, anh_url)
     VALUES ($1, $2, $3, $4, $5, $6)`,
    [nhaCungCapId, cn.loai, cn.soHieu, cn.ngayCap, cn.ngayHetHan || null, cn.anhUrl || null],
  );
}

// Khóa dòng (FOR UPDATE) để hai người duyệt cùng lúc không ghi đè nhau.
async function khoaDeDuyet(q, id) {
  const { rows } = await q.query(
    'SELECT trang_thai_duyet, anh_co_so_url FROM nha_cung_cap WHERE id = $1 FOR UPDATE',
    [id],
  );
  return camel(rows[0]);
}

async function coChungNhanOcopHieuLuc(q, id) {
  const { rowCount } = await q.query(
    `SELECT 1 FROM chung_nhan WHERE nha_cung_cap_id = $1 AND loai = 'OCOP'
       AND (ngay_het_han IS NULL OR ngay_het_han >= ${HOM_NAY_SQL})`,
    [id],
  );
  return rowCount > 0;
}

async function capNhatDuyet(q, id, { trangThai, lyDoTuChoi, nguoiDuyetId }) {
  await q.query(
    `UPDATE nha_cung_cap
     SET trang_thai_duyet = $2, ly_do_tu_choi = $3, nguoi_duyet_id = $4, duyet_luc = now()
     WHERE id = $1`,
    [id, trangThai, lyDoTuChoi, nguoiDuyetId],
  );
}

module.exports = {
  dsDaDuyet, timDaDuyet, sanPhamDaDuyet, dsChungNhan, dsQuanTri, timQuanTri, vungTonTai,
  themNhaCungCap, themChungNhan, khoaDeDuyet, coChungNhanOcopHieuLuc, capNhatDuyet,
  timTheoTaiKhoan, capNhatHoSoChoDuyetLai, xoaChungNhan,
};
