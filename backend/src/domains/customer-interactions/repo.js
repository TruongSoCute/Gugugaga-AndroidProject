'use strict';

const { withApiColumns, camel } = require('../../utils/sql');

const SP_CONG_BO = "sp.approval_status = 'DA_DUYET' AND ncc.approval_status = 'DA_DUYET'";

async function sanPhamCongBo(q, id) {
  const { rowCount } = await q.query(
    `SELECT 1 FROM products sp JOIN suppliers ncc ON ncc.id = sp.supplier_id WHERE sp.id = $1 AND ${SP_CONG_BO}`,
    [id],
  );
  return rowCount > 0;
}

async function nhaCungCapDaDuyet(q, id) {
  const { rowCount } = await q.query("SELECT 1 FROM suppliers WHERE id = $1 AND approval_status = 'DA_DUYET'", [id]);
  return rowCount > 0;
}

// Chỉ trả sản phẩm còn đang bán (bị thu hồi duyệt thì ẩn khỏi danh sách yêu thích).
async function dsYeuThich(q, nguoiDungId) {
  const { rows } = withApiColumns(await q.query(
    `SELECT sp.id, sp.name, sp.price_vnd, sp.unit, sp.ocop_rating, sp.image_url,
            ncc.id AS nha_cung_cap_id, ncc.name AS ten_nha_cung_cap, yt.created_at
     FROM product_favorites yt
     JOIN products sp ON sp.id = yt.product_id
     JOIN suppliers ncc ON ncc.id = sp.supplier_id
     WHERE yt.user_id = $1 AND ${SP_CONG_BO}
     ORDER BY yt.created_at DESC, sp.id`,
    [nguoiDungId],
  ));
  return rows.map(camel);
}

async function themYeuThich(q, nguoiDungId, sanPhamId) {
  await q.query(
    'INSERT INTO product_favorites (user_id, product_id) VALUES ($1, $2) ON CONFLICT DO NOTHING',
    [nguoiDungId, sanPhamId],
  );
}

async function boYeuThich(q, nguoiDungId, sanPhamId) {
  await q.query('DELETE FROM product_favorites WHERE user_id = $1 AND product_id = $2', [nguoiDungId, sanPhamId]);
}

async function dsTheoDoi(q, nguoiDungId) {
  const { rows } = withApiColumns(await q.query(
    `SELECT ncc.id, ncc.name, ncc.address, ncc.facility_image_url, v.name AS ten_vung, td.created_at,
            (SELECT count(*) FROM products sp WHERE sp.supplier_id = ncc.id AND sp.approval_status = 'DA_DUYET') AS so_san_pham
     FROM supplier_follows td
     JOIN suppliers ncc ON ncc.id = td.supplier_id
     JOIN sourcing_regions v ON v.id = ncc.sourcing_region_id
     WHERE td.user_id = $1 AND ncc.approval_status = 'DA_DUYET'
     ORDER BY td.created_at DESC, ncc.id`,
    [nguoiDungId],
  ));
  return rows.map(camel);
}

async function themTheoDoi(q, nguoiDungId, nccId) {
  await q.query(
    'INSERT INTO supplier_follows (user_id, supplier_id) VALUES ($1, $2) ON CONFLICT DO NOTHING',
    [nguoiDungId, nccId],
  );
}

async function boTheoDoi(q, nguoiDungId, nccId) {
  await q.query('DELETE FROM supplier_follows WHERE user_id = $1 AND supplier_id = $2', [nguoiDungId, nccId]);
}

module.exports = {
  sanPhamCongBo, nhaCungCapDaDuyet, dsYeuThich, themYeuThich, boYeuThich, dsTheoDoi, themTheoDoi, boTheoDoi,
};
