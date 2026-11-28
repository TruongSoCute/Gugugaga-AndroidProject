'use strict';

const { withApiColumns, camel, HOM_NAY_SQL } = require('../../utils/sql');

// Sản phẩm đang bán: chính nó và nhà cung cấp đều đã được duyệt.
const CONG_BO = "sp.approval_status = 'DA_DUYET' AND ncc.approval_status = 'DA_DUYET'";
// Lô còn bán được: còn hàng và chưa hết hạn sử dụng (theo ngày Việt Nam).
const LO_CON_BAN = `lo.available_quantity > 0 AND lo.expires_on > ${HOM_NAY_SQL}`;

// ---------------------------------------------------------------------------
// Giỏ hàng
// ---------------------------------------------------------------------------

async function gioHang(q, khachId) {
  const { rows } = withApiColumns(await q.query(
    `SELECT g.product_id, sp.name, sp.image_url, sp.unit, sp.price_vnd, g.quantity,
            g.quantity * sp.price_vnd AS thanh_tien,
            (${CONG_BO}) AS dang_ban,
            COALESCE((SELECT sum(lo.available_quantity) FROM production_batches lo
                      WHERE lo.product_id = g.product_id AND ${LO_CON_BAN}), 0) AS con_hang
     FROM cart_items g
     JOIN products sp ON sp.id = g.product_id
     JOIN suppliers ncc ON ncc.id = sp.supplier_id
     WHERE g.user_id = $1
     ORDER BY g.added_at, g.product_id`,
    [khachId],
  ));
  return rows.map(camel);
}

async function sanPhamDangBan(q, sanPhamId) {
  const { rows } = withApiColumns(await q.query(
    `SELECT sp.id, sp.name, sp.price_vnd FROM products sp
     JOIN suppliers ncc ON ncc.id = sp.supplier_id
     WHERE sp.id = $1 AND ${CONG_BO}`,
    [sanPhamId],
  ));
  return camel(rows[0]);
}

// Thêm mới hoặc đặt lại số lượng của sản phẩm trong giỏ.
async function datVaoGio(q, khachId, sanPhamId, soLuong) {
  await q.query(
    `INSERT INTO cart_items (user_id, product_id, quantity) VALUES ($1, $2, $3)
     ON CONFLICT (user_id, product_id) DO UPDATE SET quantity = EXCLUDED.quantity`,
    [khachId, sanPhamId, soLuong],
  );
}

async function xoaKhoiGio(q, khachId, sanPhamIds) {
  const { rowCount } = await q.query(
    'DELETE FROM cart_items WHERE user_id = $1 AND product_id = ANY($2::int[])',
    [khachId, sanPhamIds],
  );
  return rowCount;
}

// Các dòng trong giỏ, khóa lại để hai lần đặt cùng lúc không đặt trùng một giỏ.
async function khoaGio(q, khachId) {
  const { rows } = withApiColumns(await q.query(
    `SELECT product_id, quantity FROM cart_items WHERE user_id = $1
     ORDER BY product_id FOR UPDATE`,
    [khachId],
  ));
  return rows.map(camel);
}

// ---------------------------------------------------------------------------
// Đặt đơn
// ---------------------------------------------------------------------------

// Sản phẩm đang bán trong danh sách id, kèm giá hiện hành trong CSDL.
async function giaSanPhamDangBan(q, sanPhamIds) {
  const { rows } = withApiColumns(await q.query(
    `SELECT sp.id, sp.name, sp.price_vnd FROM products sp
     JOIN suppliers ncc ON ncc.id = sp.supplier_id
     WHERE sp.id = ANY($1::int[]) AND ${CONG_BO}`,
    [sanPhamIds],
  ));
  return rows.map(camel);
}

// Khóa (FOR UPDATE) mọi lô còn bán của các sản phẩm, theo thứ tự id để mọi transaction
// khóa cùng một thứ tự và không gây deadlock. Đơn khác đặt cùng lúc phải chờ transaction
// này xong, rồi đọc lại so_luong_con mới, nên không bán vượt tồn.
async function khoaLoConBan(q, sanPhamIds) {
  const { rows } = withApiColumns(await q.query(
    `SELECT lo.id, lo.product_id, lo.produced_on, lo.available_quantity
     FROM production_batches lo
     WHERE lo.product_id = ANY($1::int[]) AND ${LO_CON_BAN}
     ORDER BY lo.id
     FOR UPDATE`,
    [sanPhamIds],
  ));
  return rows.map(camel);
}

async function themDon(q, d) {
  const { rows } = withApiColumns(await q.query(
    `INSERT INTO orders
       (customer_id, delivery_method, delivery_fee_vnd, subtotal_vnd, total_vnd,
        recipient_name, recipient_phone, delivery_address, notes)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9) RETURNING id`,
    [d.khachId, d.hinhThucGiao, d.phiGiao, d.tienHang, d.tongTien,
      d.tenNguoiNhan, d.sdtNguoiNhan, d.diaChiGiao, d.ghiChu || null],
  ));
  return rows[0].id;
}

async function themChiTiet(q, donId, ct) {
  await q.query(
    `INSERT INTO order_items (order_id, product_id, batch_id, quantity, unit_price_vnd)
     VALUES ($1, $2, $3, $4, $5)`,
    [donId, ct.sanPhamId, ct.loId, ct.soLuong, ct.donGia],
  );
}

// Trừ (soLuong > 0) hoặc hoàn (soLuong < 0) tồn của lô. CHECK trong CSDL chặn tồn âm.
async function truTonLo(q, loId, soLuong) {
  await q.query('UPDATE production_batches SET available_quantity = available_quantity - $2 WHERE id = $1', [loId, soLuong]);
}

async function khoaLoTheoId(q, loIds) {
  await q.query('SELECT id FROM production_batches WHERE id = ANY($1::int[]) ORDER BY id FOR UPDATE', [loIds]);
}

async function themLichSu(q, donId, trangThai, ghiChu, nguoiThucHienId) {
  await q.query(
    `INSERT INTO order_status_history (order_id, status, notes, changed_by_user_id)
     VALUES ($1, $2, $3, $4)`,
    [donId, trangThai, ghiChu || null, nguoiThucHienId],
  );
}

// ---------------------------------------------------------------------------
// Xem và xử lý đơn
// ---------------------------------------------------------------------------

// Danh sách đơn. khachId = null: mọi khách (nhân sự xem).
async function dsDon(q, { khachId, trangThai, limit, offset }) {
  const { rows } = withApiColumns(await q.query(
    `SELECT dh.id, dh.status, dh.delivery_method, dh.total_vnd, dh.created_at, dh.updated_at,
            dh.customer_id, nd.full_name AS ten_khach, dh.recipient_name,
            ct.so_san_pham, ct.ten_san_pham_dau, ct.anh_san_pham_dau,
            count(*) OVER () AS tong
     FROM orders dh
     JOIN users nd ON nd.id = dh.customer_id
     JOIN LATERAL (
       SELECT count(DISTINCT c.product_id) AS so_san_pham,
              (array_agg(sp.name ORDER BY c.id))[1] AS ten_san_pham_dau,
              (array_agg(sp.image_url ORDER BY c.id))[1] AS anh_san_pham_dau
       FROM order_items c JOIN products sp ON sp.id = c.product_id
       WHERE c.order_id = dh.id
     ) ct ON TRUE
     WHERE ($1::int IS NULL OR dh.customer_id = $1)
       AND ($2::varchar IS NULL OR dh.status = $2)
     ORDER BY dh.created_at DESC, dh.id DESC
     LIMIT $3 OFFSET $4`,
    [khachId ?? null, trangThai ?? null, limit, offset],
  ));
  return rows;
}

async function timDon(q, id) {
  const { rows } = withApiColumns(await q.query(
    `SELECT dh.id, dh.customer_id, nd.full_name AS ten_khach, nd.email AS email_khach,
            dh.status, dh.delivery_method, dh.delivery_fee_vnd, dh.subtotal_vnd, dh.total_vnd,
            dh.recipient_name, dh.recipient_phone, dh.delivery_address, dh.notes,
            dh.created_at, dh.updated_at
     FROM orders dh JOIN users nd ON nd.id = dh.customer_id
     WHERE dh.id = $1`,
    [id],
  ));
  return camel(rows[0]);
}

// Mỗi dòng là một lô thực tế đã giao: kèm mã truy xuất để khách tra nguồn gốc hàng đã mua.
async function chiTietDon(q, donId) {
  const { rows } = withApiColumns(await q.query(
    `SELECT c.product_id, sp.name AS ten_san_pham, sp.image_url, sp.unit,
            c.batch_id, lo.traceability_code, lo.produced_on, v.name AS vung_nguyen_lieu,
            c.quantity, c.unit_price_vnd, c.quantity * c.unit_price_vnd AS thanh_tien,
            EXISTS (SELECT 1 FROM reviews dg JOIN orders d2 ON d2.id = c.order_id
                    WHERE dg.order_id = c.order_id AND dg.product_id = c.product_id
                      AND dg.customer_id = d2.customer_id) AS da_danh_gia
     FROM order_items c
     JOIN products sp ON sp.id = c.product_id
     JOIN production_batches lo ON lo.id = c.batch_id
     JOIN sourcing_regions v ON v.id = lo.sourcing_region_id
     WHERE c.order_id = $1
     ORDER BY c.id`,
    [donId],
  ));
  return rows.map(camel);
}

async function lichSuDon(q, donId) {
  const { rows } = withApiColumns(await q.query(
    `SELECT ls.status, ls.notes, ls.changed_at, nd.full_name AS nguoi_thuc_hien
     FROM order_status_history ls
     LEFT JOIN users nd ON nd.id = ls.changed_by_user_id
     WHERE ls.order_id = $1
     ORDER BY ls.changed_at, ls.id`,
    [donId],
  ));
  return rows.map(camel);
}

async function khoaDon(q, id) {
  const { rows } = withApiColumns(await q.query('SELECT id, customer_id, status FROM orders WHERE id = $1 FOR UPDATE', [id]));
  return camel(rows[0]);
}

async function capNhatTrangThai(q, id, trangThai) {
  await q.query('UPDATE orders SET status = $2, updated_at = now() WHERE id = $1', [id, trangThai]);
}

async function soLuongTheoLo(q, donId) {
  const { rows } = withApiColumns(await q.query(
    'SELECT batch_id, quantity FROM order_items WHERE order_id = $1 ORDER BY batch_id',
    [donId],
  ));
  return rows.map(camel);
}

module.exports = {
  gioHang, sanPhamDangBan, datVaoGio, xoaKhoiGio, khoaGio,
  giaSanPhamDangBan, khoaLoConBan, themDon, themChiTiet, truTonLo, khoaLoTheoId, themLichSu,
  dsDon, timDon, chiTietDon, lichSuDon, khoaDon, capNhatTrangThai, soLuongTheoLo,
};
