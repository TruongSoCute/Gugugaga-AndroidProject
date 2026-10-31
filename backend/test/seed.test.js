'use strict';

const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');
const { setup } = require('./helpers');

let t;
before(async () => { t = await setup(); });
after(async () => { await t.teardown(); });

const count = async (sql) => (await t.pool.query(sql)).rows[0].n;

test('Dữ liệu mẫu đủ số lượng tối thiểu theo đề', async () => {
  assert.ok(await count('SELECT count(*) n FROM vung_nguyen_lieu') >= 4);
  assert.ok(await count('SELECT count(*) n FROM nha_cung_cap') >= 12);
  assert.ok(await count('SELECT count(*) n FROM san_pham') >= 60);
  assert.ok(await count('SELECT count(*) n FROM lo_san_xuat') >= 100);
  assert.ok(await count('SELECT count(*) n FROM don_hang') >= 50);
});

test('Mỗi lô mẫu có đủ 4 bước và mã truy xuất khác nhau', async () => {
  const thieu = await count(`SELECT count(*) n FROM lo_san_xuat lo
    WHERE (SELECT count(*) FROM buoc_truy_xuat b WHERE b.lo_id = lo.id) < 4`);
  assert.equal(thieu, 0);
  assert.equal(await count('SELECT count(DISTINCT ma_truy_xuat) n FROM lo_san_xuat'), await count('SELECT count(*) n FROM lo_san_xuat'));
});

test('Tổng tiền đơn mẫu khớp chi tiết và tồn lô khớp số đã bán', async () => {
  assert.equal(await count(`SELECT count(*) n FROM don_hang dh
    WHERE tien_hang <> (SELECT sum(so_luong * don_gia) FROM chi_tiet_don WHERE don_hang_id = dh.id)`), 0);
  assert.equal(await count(`SELECT count(*) n FROM lo_san_xuat lo
    WHERE so_luong - so_luong_con <> COALESCE((SELECT sum(ct.so_luong) FROM chi_tiet_don ct
      JOIN don_hang dh ON dh.id = ct.don_hang_id
      WHERE ct.lo_id = lo.id AND dh.trang_thai <> 'DA_HUY'), 0)`), 0);
});

test('Ràng buộc CSDL từ chối mã truy xuất trùng và mã sai định dạng', async () => {
  const { rows } = await t.pool.query('SELECT san_pham_id, ma_truy_xuat, vung_nguyen_lieu_id FROM lo_san_xuat LIMIT 1');
  const lo = rows[0];
  const insert = (ma) => t.pool.query(
    `INSERT INTO lo_san_xuat (san_pham_id, ma_truy_xuat, ngay_san_xuat, han_su_dung, so_luong, so_luong_con,
       vung_nguyen_lieu_id, nguoi_san_xuat) VALUES ($1, $2, '2026-01-01', '2027-01-01', 10, 10, $3, 'X')`,
    [lo.san_pham_id, ma, lo.vung_nguyen_lieu_id],
  );
  await assert.rejects(insert(lo.ma_truy_xuat), { code: '23505' });
  await assert.rejects(insert('LO-001'), { code: '23514' });
});

test('Chi tiết đơn không thể ghi lô thuộc sản phẩm khác', async () => {
  const lo = (await t.pool.query('SELECT id, san_pham_id FROM lo_san_xuat ORDER BY id LIMIT 1')).rows[0];
  const spKhac = (await t.pool.query('SELECT id FROM san_pham WHERE id <> $1 LIMIT 1', [lo.san_pham_id])).rows[0].id;
  await assert.rejects(
    t.pool.query('INSERT INTO chi_tiet_don (don_hang_id, san_pham_id, lo_id, so_luong, don_gia) VALUES (1, $1, $2, 1, 1000)',
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
  assert.equal(await count('SELECT count(*) n FROM lo_san_xuat'), 100);
});
