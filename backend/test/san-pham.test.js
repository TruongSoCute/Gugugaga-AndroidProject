'use strict';

const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');
const { setup } = require('./helpers');

let t;
let nhanVien;
before(async () => {
  t = await setup();
  nhanVien = await t.login('nhanvien@ocop.example');
});
after(async () => { await t.teardown(); });

test('Danh sách công khai chỉ gồm sản phẩm đã duyệt của nhà cung cấp đã duyệt', async () => {
  const r = await t.api('GET', '/san-pham?kichThuoc=100');
  assert.equal(r.status, 200);
  assert.equal(r.body.phanTrang.tong, 48);
  const { rows } = await t.pool.query(
    `SELECT sp.id FROM san_pham sp JOIN nha_cung_cap n ON n.id = sp.nha_cung_cap_id
     WHERE sp.trang_thai_duyet <> 'DA_DUYET' OR n.trang_thai_duyet <> 'DA_DUYET'`,
  );
  const an = new Set(rows.map((x) => x.id));
  assert.equal(r.body.duLieu.some((x) => an.has(x.id)), false);
  assert.equal(typeof r.body.duLieu[0].gia, 'number');
});

test('Lọc theo vùng và hạng sao', async () => {
  const r = await t.api('GET', '/san-pham?vung=1&hangSao=5&kichThuoc=100');
  assert.equal(r.status, 200);
  assert.ok(r.body.duLieu.length > 0);
  for (const sp of r.body.duLieu) {
    assert.equal(sp.vungId, 1);
    assert.equal(sp.hangSao, 5);
  }
  const { rows } = await t.pool.query(
    `SELECT count(*) n FROM san_pham sp JOIN nha_cung_cap n ON n.id = sp.nha_cung_cap_id
     WHERE sp.trang_thai_duyet = 'DA_DUYET' AND n.trang_thai_duyet = 'DA_DUYET' AND n.vung_id = 1 AND sp.hang_sao = 5`,
  );
  assert.equal(r.body.phanTrang.tong, rows[0].n);
});

test('Tìm theo từ khóa, ký tự đặc biệt không làm lỗi truy vấn', async () => {
  const r = await t.api('GET', `/san-pham?tuKhoa=${encodeURIComponent('hạt điều')}`);
  assert.equal(r.status, 200);
  assert.ok(r.body.duLieu.length >= 3);
  assert.ok(r.body.duLieu.every((x) => x.ten.toLowerCase().includes('hạt điều')));
  const pct = await t.api('GET', `/san-pham?tuKhoa=${encodeURIComponent("%' OR 1=1 --")}`);
  assert.equal(pct.status, 200);
  assert.equal(pct.body.duLieu.length, 0);
});

test('Tham số lọc sai trả 400', async () => {
  assert.equal((await t.api('GET', '/san-pham?hangSao=7')).status, 400);
  assert.equal((await t.api('GET', '/san-pham?vung=abc')).status, 400);
  assert.equal((await t.api('GET', '/san-pham/abc')).status, 400);
  assert.equal((await t.api('GET', '/san-pham/999999')).status, 404);
});

test('Chi tiết sản phẩm công khai có nhà cung cấp, chứng nhận và đánh giá, không lộ email', async () => {
  const { rows } = await t.pool.query('SELECT san_pham_id FROM danh_gia ORDER BY id LIMIT 1');
  const r = await t.api('GET', `/san-pham/${rows[0].san_pham_id}`);
  assert.equal(r.status, 200);
  assert.ok(r.body.tenNhaCungCap);
  assert.ok(r.body.chungNhan.length >= 1);
  assert.ok(r.body.soDanhGia >= 1);
  assert.ok(r.body.danhGiaGanDay[0].tenNguoiDanhGia);
  assert.equal(JSON.stringify(r.body).includes('@ocop.example'), false);
});

test('Danh sách quản trị lọc theo trạng thái chờ duyệt', async () => {
  const r = await t.api('GET', '/quan-tri/san-pham?trangThai=CHO_DUYET&kichThuoc=100', { token: nhanVien });
  assert.equal(r.status, 200);
  assert.equal(r.body.phanTrang.tong, 11);
  assert.ok(r.body.duLieu.every((x) => x.trangThaiDuyet === 'CHO_DUYET'));
  assert.equal((await t.api('GET', '/quan-tri/san-pham')).status, 401);
  const ncc = await t.api('GET', '/quan-tri/nha-cung-cap?trangThai=TU_CHOI', { token: nhanVien });
  assert.equal(ncc.status, 200);
  assert.equal(ncc.body.duLieu.length, 1);
  assert.ok(ncc.body.duLieu[0].lyDoTuChoi);
});

test('Vùng nguyên liệu và nhà cung cấp công khai', async () => {
  const v = await t.api('GET', '/vung-nguyen-lieu');
  assert.equal(v.status, 200);
  assert.ok(v.body.length >= 4);
  const n = await t.api('GET', '/nha-cung-cap?vung=1');
  assert.equal(n.status, 200);
  assert.ok(n.body.length >= 1 && n.body.every((x) => x.vungId === 1 && x.trangThaiDuyet === 'DA_DUYET'));
  const ct = await t.api('GET', `/nha-cung-cap/${n.body[0].id}`);
  assert.equal(ct.status, 200);
  assert.ok(ct.body.sanPham.length >= 1);
  // NCC 11 đang chờ duyệt.
  assert.equal((await t.api('GET', '/nha-cung-cap/11')).status, 404);
});

test('Không thêm sản phẩm cho nhà cung cấp bị từ chối; không tạo lô cho sản phẩm bị từ chối', async () => {
  const a = await t.api('POST', '/san-pham', { token: nhanVien, body: { nhaCungCapId: 12, ten: 'X', gia: 1000 } });
  assert.equal(a.status, 409);
  const b = await t.api('POST', '/lo-san-xuat', {
    token: nhanVien,
    body: { sanPhamId: 50, ngaySanXuat: '2026-10-01', hanSuDung: '2027-10-01', soLuong: 1, nguoiSanXuat: 'A' },
  });
  assert.equal(b.status, 409);
});
