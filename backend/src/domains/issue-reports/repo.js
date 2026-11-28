'use strict';

const { withApiColumns, camel } = require('../../utils/sql');

async function sanPhamTonTai(q, sanPhamId) {
  const { rowCount } = await q.query('SELECT 1 FROM products WHERE id = $1', [sanPhamId]);
  return rowCount > 0;
}

async function loTheoMa(q, maTruyXuat) {
  const { rows } = withApiColumns(await q.query('SELECT id, product_id FROM production_batches WHERE traceability_code = $1', [maTruyXuat]));
  return camel(rows[0]);
}

async function them(q, d) {
  const { rows } = withApiColumns(await q.query(
    `INSERT INTO issue_reports (reporter_id, product_id, batch_id, report_type, description, image_url)
     VALUES ($1, $2, $3, $4, $5, $6) RETURNING id`,
    [d.nguoiBaoId, d.sanPhamId, d.loId ?? null, d.loai, d.noiDung, d.anhUrl || null],
  ));
  return rows[0].id;
}

const COT = `bc.id, bc.product_id, sp.name AS ten_san_pham, sp.image_url AS anh_san_pham,
  ncc.id AS nha_cung_cap_id, ncc.name AS ten_nha_cung_cap,
  bc.batch_id, lo.traceability_code, bc.report_type, bc.description AS noi_dung, bc.image_url, bc.status, bc.resolution,
  bc.handled_at, bc.created_at, bc.reporter_id, nb.full_name AS ten_nguoi_bao, xl.full_name AS ten_nguoi_xu_ly`;
const FROM = `FROM issue_reports bc
  JOIN products sp ON sp.id = bc.product_id
  JOIN suppliers ncc ON ncc.id = sp.supplier_id
  JOIN users nb ON nb.id = bc.reporter_id
  LEFT JOIN users xl ON xl.id = bc.handled_by_user_id
  LEFT JOIN production_batches lo ON lo.id = bc.batch_id`;

// Nhân sự xem thêm email người báo để liên hệ; khách chỉ xem phản ánh của chính mình.
async function timTheoId(q, id) {
  const { rows } = withApiColumns(await q.query(`SELECT ${COT}, nb.email AS email_nguoi_bao ${FROM} WHERE bc.id = $1`, [id]));
  return camel(rows[0]);
}

// nguoiBaoId = null: mọi phản ánh (nhân sự). Phản ánh mới (MOI) xếp trước.
async function ds(q, { nguoiBaoId, trangThai, loai, limit, offset }) {
  const { rows } = withApiColumns(await q.query(
    `SELECT ${COT}, count(*) OVER () AS tong ${FROM}
     WHERE ($1::int IS NULL OR bc.reporter_id = $1)
       AND ($2::varchar IS NULL OR bc.status = $2)
       AND ($3::varchar IS NULL OR bc.report_type = $3)
     ORDER BY (bc.status = 'MOI') DESC, bc.created_at DESC, bc.id DESC
     LIMIT $4 OFFSET $5`,
    [nguoiBaoId ?? null, trangThai ?? null, loai ?? null, limit, offset],
  ));
  return rows;
}

async function khoa(q, id) {
  const { rows } = withApiColumns(await q.query('SELECT status FROM issue_reports WHERE id = $1 FOR UPDATE', [id]));
  return camel(rows[0]);
}

async function capNhatXuLy(q, id, { trangThai, ketQuaXuLy, nguoiXuLyId, ketThuc }) {
  await q.query(
    `UPDATE issue_reports
     SET status = $2, resolution = COALESCE($3, resolution), handled_by_user_id = $4,
         handled_at = CASE WHEN $5::boolean THEN now() ELSE handled_at END
     WHERE id = $1`,
    [id, trangThai, ketQuaXuLy || null, nguoiXuLyId, ketThuc],
  );
}

module.exports = { sanPhamTonTai, loTheoMa, them, timTheoId, ds, khoa, capNhatXuLy };
