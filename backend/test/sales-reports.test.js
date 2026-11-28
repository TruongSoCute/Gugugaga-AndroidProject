'use strict';

// Báo cáo doanh số: đúng số liệu tính trực tiếp từ CSDL, chỉ quản trị xem được.
const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');
const { setup } = require('./helpers');

let t;
let quanTri;
before(async () => { t = await setup(); quanTri = await t.login('quantri@ocop.example'); });
after(async () => { await t.teardown(); });

const tinhTay = async (dieuKien = 'TRUE', params = []) => (await t.pool.query(
  `SELECT COALESCE(sum(c.so_luong * c.don_gia), 0)::bigint AS n FROM chi_tiet_don c
   JOIN don_hang dh ON dh.id = c.don_hang_id JOIN lo_san_xuat lo ON lo.id = c.lo_id
   WHERE dh.trang_thai IN ('DA_GIAO', 'DA_NHAN') AND ${dieuKien}`, params,
)).rows[0].n;

test('Chỉ quản trị xem báo cáo doanh số', async () => {
  assert.equal((await t.api('GET', '/bao-cao/doanh-so')).status, 401);
  for (const email of ['nhanvien@ocop.example', 'khach1@ocop.example', 'ncc1@ocop.example']) {
    assert.equal((await t.api('GET', '/bao-cao/doanh-so', { token: await t.login(email) })).status, 403, email);
  }
});

test('Tổng doanh số khớp CSDL; theo vùng, theo hạng sao cộng lại bằng tổng', async () => {
  const r = await t.api('GET', '/bao-cao/doanh-so', { token: quanTri });
  assert.equal(r.status, 200);
  const tong = await tinhTay();
  assert.ok(tong > 0);
  assert.equal(r.body.tong.doanhSo, tong);
  assert.equal(r.body.theoVung.length, 5);
  assert.equal(r.body.theoVung.reduce((x, v) => x + v.doanhSo, 0), tong);
  assert.deepEqual(r.body.theoHangSao.map((h) => h.hangSao), [3, 4, 5]);
  assert.equal(r.body.theoHangSao.reduce((x, v) => x + v.doanhSo, 0), tong);
  assert.ok(r.body.nhaCungCapBanChay.length <= 5);
  const ds = r.body.nhaCungCapBanChay.map((x) => x.doanhSo);
  assert.deepEqual(ds, [...ds].sort((a, b) => b - a));
});

test('Lọc theo vùng của lô và khoảng ngày; tham số sai 400', async () => {
  const vung = await t.api('GET', '/bao-cao/doanh-so?vung=1', { token: quanTri });
  assert.equal(vung.body.tong.doanhSo, await tinhTay('lo.vung_nguyen_lieu_id = $1', [1]));
  assert.deepEqual(vung.body.theoVung.map((v) => v.vungId), [1]);

  const ngay = await t.api('GET', '/bao-cao/doanh-so?tu=2026-07-01&den=2026-07-31', { token: quanTri });
  assert.equal(ngay.body.tong.doanhSo, await tinhTay(
    "(dh.tao_luc AT TIME ZONE 'Asia/Ho_Chi_Minh')::date BETWEEN '2026-07-01' AND '2026-07-31'",
  ));
  const rong = await t.api('GET', '/bao-cao/doanh-so?tu=2030-01-01', { token: quanTri });
  assert.equal(rong.body.tong.doanhSo, 0);
  assert.equal(rong.body.theoVung.length, 5);

  assert.equal((await t.api('GET', '/bao-cao/doanh-so?tu=2026-08-01&den=2026-07-01', { token: quanTri })).status, 400);
  assert.equal((await t.api('GET', '/bao-cao/doanh-so?tu=hom-qua', { token: quanTri })).status, 400);
});
