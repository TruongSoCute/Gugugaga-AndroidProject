'use strict';

// Tầng repo: chỉ chứa câu SQL tham số hóa ($1, $2...). Tham số đầu `q` là pool
// hoặc client của transaction, do tầng service truyền vào.
const { withApiColumns, camel, HOM_NAY_SQL } = require('../../utils/sql');

const COT = `ncc.id, ncc.name, ncc.representative_name, ncc.phone_number, ncc.address,
  ncc.sourcing_region_id, v.name AS ten_vung, ncc.facility_image_url, ncc.approval_status`;
const SO_NGUOI_THEO_DOI = `(SELECT count(*) FROM supplier_follows t
  WHERE t.supplier_id = ncc.id) AS so_nguoi_theo_doi`;

async function dsDaDuyet(q, vungId) {
  const { rows } = withApiColumns(await q.query(
    `SELECT ${COT}, ${SO_NGUOI_THEO_DOI}
     FROM suppliers ncc JOIN sourcing_regions v ON v.id = ncc.sourcing_region_id
     WHERE ncc.approval_status = 'DA_DUYET' AND ($1::int IS NULL OR ncc.sourcing_region_id = $1)
     ORDER BY ncc.name`,
    [vungId ?? null],
  ));
  return rows.map(camel);
}

async function timDaDuyet(q, id) {
  const { rows } = withApiColumns(await q.query(
    `SELECT ${COT}, ${SO_NGUOI_THEO_DOI}
     FROM suppliers ncc JOIN sourcing_regions v ON v.id = ncc.sourcing_region_id
     WHERE ncc.id = $1 AND ncc.approval_status = 'DA_DUYET'`,
    [id],
  ));
  return camel(rows[0]);
}

async function sanPhamDaDuyet(q, nhaCungCapId) {
  const { rows } = withApiColumns(await q.query(
    `SELECT id, name, price_vnd, unit, ocop_rating, image_url FROM products
     WHERE supplier_id = $1 AND approval_status = 'DA_DUYET' ORDER BY name`,
    [nhaCungCapId],
  ));
  return rows.map(camel);
}

async function dsChungNhan(q, nhaCungCapId) {
  const { rows } = withApiColumns(await q.query(
    `SELECT id, certificate_type, certificate_number, issued_on, expires_on AS ngay_het_han, image_url,
            (expires_on IS NULL OR expires_on >= ${HOM_NAY_SQL}) AS con_hieu_luc
     FROM certificates WHERE supplier_id = $1 ORDER BY certificate_type, issued_on`,
    [nhaCungCapId],
  ));
  return rows.map(camel);
}

// Danh sách cho app Admin: mọi trạng thái, hồ sơ chờ duyệt xếp trước. Có cột "tong".
async function dsQuanTri(q, { trangThai, vung, limit, offset }) {
  const { rows } = withApiColumns(await q.query(
    `SELECT ${COT}, ncc.rejection_reason, ncc.created_at, (ncc.account_id IS NOT NULL) AS tu_gui,
            count(*) OVER () AS tong
     FROM suppliers ncc JOIN sourcing_regions v ON v.id = ncc.sourcing_region_id
     WHERE ($1::text IS NULL OR ncc.approval_status = $1)
       AND ($2::int IS NULL OR ncc.sourcing_region_id = $2)
     ORDER BY (ncc.approval_status = 'CHO_DUYET') DESC, ncc.created_at DESC
     LIMIT $3 OFFSET $4`,
    [trangThai ?? null, vung ?? null, limit, offset],
  ));
  return rows;
}

async function timQuanTri(q, id) {
  const { rows } = withApiColumns(await q.query(
    `SELECT ${COT}, ncc.rejection_reason, ncc.reviewed_at, ncc.created_at, nd.full_name AS nguoi_duyet,
            (ncc.account_id IS NOT NULL) AS tu_gui
     FROM suppliers ncc
     JOIN sourcing_regions v ON v.id = ncc.sourcing_region_id
     LEFT JOIN users nd ON nd.id = ncc.reviewed_by_user_id
     WHERE ncc.id = $1`,
    [id],
  ));
  return camel(rows[0]);
}

async function vungTonTai(q, vungId) {
  const { rowCount } = await q.query('SELECT 1 FROM sourcing_regions WHERE id = $1', [vungId]);
  return rowCount > 0;
}

// taiKhoanId: tài khoản NHA_CUNG_CAP sở hữu hồ sơ (null khi nhân sự nhập hộ).
async function themNhaCungCap(q, d, nguoiTaoId, taiKhoanId = null) {
  const { rows } = withApiColumns(await q.query(
    `INSERT INTO suppliers
       (name, representative_name, phone_number, address, sourcing_region_id, facility_image_url, created_by_user_id, account_id)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING id`,
    [d.ten, d.nguoiDaiDien, d.soDienThoai, d.diaChi, d.vungId, d.anhCoSoUrl || null, nguoiTaoId, taiKhoanId],
  ));
  return rows[0].id;
}

// Hồ sơ của một tài khoản nhà cung cấp. khoa = true: khóa dòng để sửa trong transaction.
async function timTheoTaiKhoan(q, taiKhoanId, { khoa = false } = {}) {
  const { rows } = withApiColumns(await q.query(
    `SELECT id, approval_status FROM suppliers WHERE account_id = $1${khoa ? ' FOR UPDATE' : ''}`,
    [taiKhoanId],
  ));
  return camel(rows[0]);
}

// Nhà cung cấp sửa hồ sơ: đưa về CHO_DUYET để quản trị duyệt lại, xóa kết quả duyệt cũ.
async function capNhatHoSoChoDuyetLai(q, id, d) {
  await q.query(
    `UPDATE suppliers
     SET name = $2, representative_name = $3, phone_number = $4, address = $5, sourcing_region_id = $6, facility_image_url = $7,
         approval_status = 'CHO_DUYET', rejection_reason = NULL, reviewed_by_user_id = NULL, reviewed_at = NULL
     WHERE id = $1`,
    [id, d.ten, d.nguoiDaiDien, d.soDienThoai, d.diaChi, d.vungId, d.anhCoSoUrl || null],
  );
}

async function xoaChungNhan(q, nhaCungCapId) {
  await q.query('DELETE FROM certificates WHERE supplier_id = $1', [nhaCungCapId]);
}

async function themChungNhan(q, nhaCungCapId, cn) {
  await q.query(
    `INSERT INTO certificates (supplier_id, certificate_type, certificate_number, issued_on, expires_on, image_url)
     VALUES ($1, $2, $3, $4, $5, $6)`,
    [nhaCungCapId, cn.loai, cn.soHieu, cn.ngayCap, cn.ngayHetHan || null, cn.anhUrl || null],
  );
}

// Khóa dòng (FOR UPDATE) để hai người duyệt cùng lúc không ghi đè nhau.
async function khoaDeDuyet(q, id) {
  const { rows } = withApiColumns(await q.query(
    'SELECT approval_status, facility_image_url FROM suppliers WHERE id = $1 FOR UPDATE',
    [id],
  ));
  return camel(rows[0]);
}

async function coChungNhanOcopHieuLuc(q, id) {
  const { rowCount } = await q.query(
    `SELECT 1 FROM certificates WHERE supplier_id = $1 AND certificate_type = 'OCOP'
       AND (expires_on IS NULL OR expires_on >= ${HOM_NAY_SQL})`,
    [id],
  );
  return rowCount > 0;
}

async function capNhatDuyet(q, id, { trangThai, lyDoTuChoi, nguoiDuyetId }) {
  await q.query(
    `UPDATE suppliers
     SET approval_status = $2, rejection_reason = $3, reviewed_by_user_id = $4, reviewed_at = now()
     WHERE id = $1`,
    [id, trangThai, lyDoTuChoi, nguoiDuyetId],
  );
}

module.exports = {
  dsDaDuyet, timDaDuyet, sanPhamDaDuyet, dsChungNhan, dsQuanTri, timQuanTri, vungTonTai,
  themNhaCungCap, themChungNhan, khoaDeDuyet, coChungNhanOcopHieuLuc, capNhatDuyet,
  timTheoTaiKhoan, capNhatHoSoChoDuyetLai, xoaChungNhan,
};
