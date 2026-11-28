'use strict';

const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');
const { setup } = require('./helpers');

let t;
before(async () => { t = await setup(); });
after(async () => { await t.teardown(); });

const count = async (sql) => (await t.pool.query(sql)).rows[0].n;

test('Dữ liệu mẫu đủ số lượng tối thiểu theo đề', async () => {
  assert.ok(await count('SELECT count(*) n FROM sourcing_regions') >= 4);
  assert.ok(await count('SELECT count(*) n FROM suppliers') >= 12);
  assert.ok(await count('SELECT count(*) n FROM products') >= 60);
  assert.ok(await count('SELECT count(*) n FROM production_batches') >= 100);
  assert.ok(await count('SELECT count(*) n FROM orders') >= 50);
});

test('Mỗi lô mẫu có đủ 4 bước và mã truy xuất khác nhau', async () => {
  const thieu = await count(`SELECT count(*) n FROM production_batches lo
    WHERE (SELECT count(*) FROM traceability_steps b WHERE b.batch_id = lo.id) < 4`);
  assert.equal(thieu, 0);
  assert.equal(await count('SELECT count(DISTINCT traceability_code) n FROM production_batches'), await count('SELECT count(*) n FROM production_batches'));
});

test('Tổng tiền đơn mẫu khớp chi tiết và tồn lô khớp số đã bán', async () => {
  assert.equal(await count(`SELECT count(*) n FROM orders dh
    WHERE subtotal_vnd <> (SELECT sum(quantity * unit_price_vnd) FROM order_items WHERE order_id = dh.id)`), 0);
  assert.equal(await count(`SELECT count(*) n FROM production_batches lo
    WHERE quantity - available_quantity <> COALESCE((SELECT sum(ct.quantity) FROM order_items ct
      JOIN orders dh ON dh.id = ct.order_id
      WHERE ct.batch_id = lo.id AND dh.status <> 'DA_HUY'), 0)`), 0);
});

test('Ràng buộc CSDL từ chối mã truy xuất trùng và mã sai định dạng', async () => {
  const { rows } = await t.pool.query('SELECT product_id, traceability_code, sourcing_region_id FROM production_batches LIMIT 1');
  const lo = rows[0];
  const insert = (ma) => t.pool.query(
    `INSERT INTO production_batches (product_id, traceability_code, produced_on, expires_on, quantity, available_quantity,
       sourcing_region_id, producer_name) VALUES ($1, $2, '2026-01-01', '2027-01-01', 10, 10, $3, 'X')`,
    [lo.product_id, ma, lo.sourcing_region_id],
  );
  await assert.rejects(insert(lo.traceability_code), { code: '23505' });
  await assert.rejects(insert('LO-001'), { code: '23514' });
});

test('Chi tiết đơn không thể ghi lô thuộc sản phẩm khác', async () => {
  const lo = (await t.pool.query('SELECT id, product_id FROM production_batches ORDER BY id LIMIT 1')).rows[0];
  const spKhac = (await t.pool.query('SELECT id FROM products WHERE id <> $1 LIMIT 1', [lo.product_id])).rows[0].id;
  await assert.rejects(
    t.pool.query('INSERT INTO order_items (order_id, product_id, batch_id, quantity, unit_price_vnd) VALUES (1, $1, $2, 1, 1000)',
      [spKhac, lo.id]),
    { code: '23503' },
  );
});

test('schema.sql và seed.sql chạy lại được', async () => {
  const fs = require('node:fs');
  const path = require('node:path');
  for (const f of ['schema.sql', 'seed.sql', 'seed.sql']) {
    await t.pool.query(fs.readFileSync(path.join(__dirname, '..', 'db', f), 'utf8'));
  }
  assert.equal(await count('SELECT count(*) n FROM production_batches'), 100);
  const { rows: [schema] } = await t.pool.query(
    "SELECT to_regclass('public.danh_gia') IS NULL AS legacy_name_absent, " +
    "(SELECT relkind = 'r' FROM pg_class WHERE oid = 'public.reviews'::regclass) AS reviews_is_table",
  );
  assert.deepEqual(schema, { legacy_name_absent: true, reviews_is_table: true });
});
