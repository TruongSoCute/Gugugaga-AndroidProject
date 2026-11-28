'use strict';

const { withApiColumns, camel } = require('../../utils/sql');

async function dsLo(q, { sanPhamId, limit, offset }) {
  const { rows } = withApiColumns(await q.query(
    `SELECT lo.id, lo.traceability_code, lo.product_id, sp.name AS ten_san_pham,
            lo.produced_on, lo.expires_on, lo.quantity, lo.available_quantity,
            v.name AS ten_vung, lo.producer_name,
            (SELECT count(*) FROM traceability_steps b WHERE b.batch_id = lo.id) AS so_buoc,
            count(*) OVER () AS tong
     FROM production_batches lo
     JOIN products sp ON sp.id = lo.product_id
     JOIN sourcing_regions v ON v.id = lo.sourcing_region_id
     WHERE ($1::int IS NULL OR lo.product_id = $1)
     ORDER BY lo.created_at DESC, lo.id DESC
     LIMIT $2 OFFSET $3`,
    [sanPhamId ?? null, limit, offset],
  ));
  return rows;
}

async function timLo(q, id) {
  const { rows } = withApiColumns(await q.query(
    `SELECT lo.id, lo.traceability_code, lo.product_id, sp.name AS ten_san_pham,
            sp.approval_status AS trang_thai_san_pham,
            lo.produced_on, lo.expires_on, lo.quantity, lo.available_quantity,
            lo.sourcing_region_id AS vung_nguyen_lieu_id, v.name AS ten_vung, lo.producer_name,
            lo.site_image_url, lo.notes, lo.created_at
     FROM production_batches lo
     JOIN products sp ON sp.id = lo.product_id
     JOIN sourcing_regions v ON v.id = lo.sourcing_region_id
     WHERE lo.id = $1`,
    [id],
  ));
  return camel(rows[0]);
}

async function cacBuoc(q, loId) {
  const { rows } = withApiColumns(await q.query(
    `SELECT id, position, name AS ten_buoc, description, occurred_at, image_url
     FROM traceability_steps WHERE batch_id = $1 ORDER BY position`,
    [loId],
  ));
  return rows.map(camel);
}

// Trạng thái sản phẩm và vùng mặc định (vùng của nhà cung cấp) khi tạo lô.
async function sanPhamChoLo(q, sanPhamId) {
  const { rows } = withApiColumns(await q.query(
    `SELECT sp.approval_status, ncc.sourcing_region_id
     FROM products sp JOIN suppliers ncc ON ncc.id = sp.supplier_id
     WHERE sp.id = $1`,
    [sanPhamId],
  ));
  return camel(rows[0]);
}

async function vungTonTai(q, vungId) {
  const { rowCount } = await q.query('SELECT 1 FROM sourcing_regions WHERE id = $1', [vungId]);
  return rowCount > 0;
}

// Số lượng còn bán ban đầu bằng số lượng của lô.
async function themLo(q, d) {
  const { rows } = withApiColumns(await q.query(
    `INSERT INTO production_batches
       (product_id, traceability_code, produced_on, expires_on, quantity, available_quantity,
        sourcing_region_id, producer_name, site_image_url, notes, created_by_user_id)
     VALUES ($1, $2, $3, $4, $5, $5, $6, $7, $8, $9, $10) RETURNING id`,
    [d.sanPhamId, d.maTruyXuat, d.ngaySanXuat, d.hanSuDung, d.soLuong, d.vungNguyenLieuId,
      d.nguoiSanXuat, d.anhHienTruongUrl || null, d.ghiChu || null, d.nguoiTaoId],
  ));
  return rows[0].id;
}

async function themBuoc(q, loId, b) {
  await q.query(
    `INSERT INTO traceability_steps (batch_id, position, name, description, occurred_at, image_url)
     VALUES ($1, $2, $3, $4, $5, $6)`,
    [loId, b.thuTu, b.tenBuoc, b.moTa || null, b.thoiDiem, b.anhUrl || null],
  );
}

async function loTonTai(q, loId) {
  const { rowCount } = await q.query('SELECT 1 FROM production_batches WHERE id = $1', [loId]);
  return rowCount > 0;
}

// Thêm bước; không có thuTu thì lấy thứ tự kế tiếp trong cùng câu lệnh.
async function themBuocTuDongThuTu(q, loId, b) {
  const { rows } = withApiColumns(await q.query(
    `INSERT INTO traceability_steps (batch_id, position, name, description, occurred_at, image_url)
     SELECT $1, COALESCE($2::smallint, COALESCE(max(position), 0) + 1), $3, $4, $5, $6
     FROM traceability_steps WHERE batch_id = $1
     RETURNING id, position, name AS ten_buoc, description, occurred_at, image_url`,
    [loId, b.thuTu ?? null, b.tenBuoc, b.moTa || null, b.thoiDiem, b.anhUrl || null],
  ));
  return camel(rows[0]);
}

// Truy xuất công khai: chỉ lô của sản phẩm VÀ nhà cung cấp đang được duyệt.
async function timLoCongKhai(q, ma) {
  const { rows } = withApiColumns(await q.query(
    `SELECT lo.id AS lo_id, lo.traceability_code, lo.produced_on, lo.expires_on,
            lo.producer_name, lo.site_image_url,
            vl.id AS vung_lo_id, vl.name AS vung_lo_ten, vl.description AS vung_lo_mo_ta,
            vl.latitude AS vung_lo_vi_do, vl.longitude AS vung_lo_kinh_do,
            sp.id AS sp_id, sp.name AS sp_ten, sp.description AS sp_mo_ta, sp.unit AS sp_don_vi_tinh,
            sp.ocop_rating AS sp_hang_sao, sp.image_url AS sp_anh_url,
            ncc.id AS ncc_id, ncc.name AS ncc_ten, ncc.address AS ncc_dia_chi,
            ncc.facility_image_url AS ncc_anh_co_so_url, vn.name AS ncc_vung
     FROM production_batches lo
     JOIN products sp ON sp.id = lo.product_id
     JOIN suppliers ncc ON ncc.id = sp.supplier_id
     JOIN sourcing_regions vl ON vl.id = lo.sourcing_region_id
     JOIN sourcing_regions vn ON vn.id = ncc.sourcing_region_id
     WHERE lo.traceability_code = $1
       AND sp.approval_status = 'DA_DUYET' AND ncc.approval_status = 'DA_DUYET'`,
    [ma],
  ));
  return rows[0];
}

module.exports = {
  dsLo, timLo, cacBuoc, sanPhamChoLo, vungTonTai, themLo, themBuoc, loTonTai,
  themBuocTuDongThuTu, timLoCongKhai,
};
