'use strict';

const { camel } = require('../../utils/sql');

async function sanPhamTonTai(q, sanPhamId) {
  const { rowCount } = await q.query('SELECT 1 FROM san_pham WHERE id = $1', [sanPhamId]);
  return rowCount > 0;
}

async function loTheoMa(q, maTruyXuat) {
  const { rows } = await q.query('SELECT id, san_pham_id FROM lo_san_xuat WHERE ma_truy_xuat = $1', [maTruyXuat]);
  return camel(rows[0]);
}

async function them(q, d) {
  const { rows } = await q.query(
    `INSERT INTO bao_cao_vi_pham (nguoi_bao_id, san_pham_id, lo_id, loai, noi_dung, anh_url)
     VALUES ($1, $2, $3, $4, $5, $6) RETURNING id`,
    [d.nguoiBaoId, d.sanPhamId, d.loId ?? null, d.loai, d.noiDung, d.anhUrl || null],
  );
  return rows[0].id;
}

const COT = `bc.id, bc.san_pham_id, sp.ten AS ten_san_pham, sp.anh_url AS anh_san_pham,
  ncc.id AS nha_cung_cap_id, ncc.ten AS ten_nha_cung_cap,
  bc.lo_id, lo.ma_truy_xuat, bc.loai, bc.noi_dung, bc.anh_url, bc.trang_thai, bc.ket_qua_xu_ly,
  bc.xu_ly_luc, bc.tao_luc, bc.nguoi_bao_id, nb.ho_ten AS ten_nguoi_bao, xl.ho_ten AS ten_nguoi_xu_ly`;
const FROM = `FROM bao_cao_vi_pham bc
  JOIN san_pham sp ON sp.id = bc.san_pham_id
  JOIN nha_cung_cap ncc ON ncc.id = sp.nha_cung_cap_id
  JOIN nguoi_dung nb ON nb.id = bc.nguoi_bao_id
  LEFT JOIN nguoi_dung xl ON xl.id = bc.nguoi_xu_ly_id
  LEFT JOIN lo_san_xuat lo ON lo.id = bc.lo_id`;

// Nhân sự xem thêm email người báo để liên hệ; khách chỉ xem phản ánh của chính mình.
async function timTheoId(q, id) {
  const { rows } = await q.query(`SELECT ${COT}, nb.email AS email_nguoi_bao ${FROM} WHERE bc.id = $1`, [id]);
  return camel(rows[0]);
}

// nguoiBaoId = null: mọi phản ánh (nhân sự). Phản ánh mới (MOI) xếp trước.
async function ds(q, { nguoiBaoId, trangThai, loai, limit, offset }) {
  const { rows } = await q.query(
    `SELECT ${COT}, count(*) OVER () AS tong ${FROM}
     WHERE ($1::int IS NULL OR bc.nguoi_bao_id = $1)
       AND ($2::varchar IS NULL OR bc.trang_thai = $2)
       AND ($3::varchar IS NULL OR bc.loai = $3)
     ORDER BY (bc.trang_thai = 'MOI') DESC, bc.tao_luc DESC, bc.id DESC
     LIMIT $4 OFFSET $5`,
    [nguoiBaoId ?? null, trangThai ?? null, loai ?? null, limit, offset],
  );
  return rows;
}

async function khoa(q, id) {
  const { rows } = await q.query('SELECT trang_thai FROM bao_cao_vi_pham WHERE id = $1 FOR UPDATE', [id]);
  return camel(rows[0]);
}

async function capNhatXuLy(q, id, { trangThai, ketQuaXuLy, nguoiXuLyId, ketThuc }) {
  await q.query(
    `UPDATE bao_cao_vi_pham
     SET trang_thai = $2, ket_qua_xu_ly = COALESCE($3, ket_qua_xu_ly), nguoi_xu_ly_id = $4,
         xu_ly_luc = CASE WHEN $5::boolean THEN now() ELSE xu_ly_luc END
     WHERE id = $1`,
    [id, trangThai, ketQuaXuLy || null, nguoiXuLyId, ketThuc],
  );
}

module.exports = { sanPhamTonTai, loTheoMa, them, timTheoId, ds, khoa, capNhatXuLy };
