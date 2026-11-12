
'use strict';

const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');
const { setup } = require('./helpers');

let t;
let adminToken;

before(async () => {
  t = await setup();
  adminToken = await t.login('QuanTri@ocop.example');
});

after(async () => {
  await t.teardown();
});

test('Không có token không được quản lý tài khoản', async () => {
  const r = await t.api('GET', '/quan-tri/tai-khoan');
  assert.equal(r.status, 401);
});

test('Quản trị viên có thể tạo tài khoản NHAN_VIEN', async () => {
  const r = await t.api('POST', '/quan-tri/tai-khoan', {
    token: adminToken,
    body: {
      email: 'nhanvien-moi@ocop.example',
      matKhau: 'NhanVien123',
      hoTen: 'Nhân viên mới',
      soDienThoai: '0901234567',
    },
  });

  assert.equal(r.status, 201);
  assert.equal(r.body.vaiTro, 'NHAN_VIEN');
  assert.equal(r.body.email, 'nhanvien-moi@ocop.example');
  assert.equal(JSON.stringify(r.body).includes('matKhau'), false);

  const { rows } = await t.pool.query(
    `SELECT vai_tro, mat_khau_hash, dang_hoat_dong
     FROM nguoi_dung WHERE email = $1`,
    ['nhanvien-moi@ocop.example'],
  );

  assert.equal(rows[0].vai_tro, 'NHAN_VIEN');
  assert.equal(rows[0].dang_hoat_dong, true);
  assert.match(rows[0].mat_khau_hash, /^\$2[aby]\$10\$/);
});

test('Không cho tạo tài khoản với email đã tồn tại', async () => {
  const r = await t.api('POST', '/quan-tri/tai-khoan', {
    token: adminToken,
    body: {
      email: 'QuanTri@ocop.example',
      matKhau: 'NhanVien123',
      hoTen: 'Tài khoản trùng',
    },
  });

  assert.equal(r.status, 409);
});

test('Không cho tạo nhân viên với dữ liệu không hợp lệ', async () => {
  const r = await t.api('POST', '/quan-tri/tai-khoan', {
    token: adminToken,
    body: {
      email: 'email-khong-hop-le',
      matKhau: '123',
      hoTen: '',
    },
  });

  assert.equal(r.status, 400);
});

test('Quản trị viên xem được danh sách tài khoản', async () => {
  const r = await t.api('GET', '/quan-tri/tai-khoan', {
    token: adminToken,
  });

  assert.equal(r.status, 200);
  assert.ok(Array.isArray(r.body.duLieu));
  assert.ok(r.body.phanTrang);
  assert.ok(r.body.duLieu.some(
    (u) => u.email === 'quantri@ocop.example',
  ));
});

test('Nhân viên không được quản lý tài khoản', async () => {
  await t.api('POST', '/quan-tri/tai-khoan', {
    token: adminToken,
    body: {
      email: 'nhanvien-quyen@ocop.example',
      matKhau: 'NhanVien123',
      hoTen: 'Nhân viên kiểm tra quyền',
    },
  });

  const staffToken = await t.login(
    'nhanvien-quyen@ocop.example',
    'NhanVien123',
  );

  const r = await t.api('GET', '/quan-tri/tai-khoan', {
    token: staffToken,
  });

  assert.equal(r.status, 403);
});

test('Quản trị viên có thể khóa và mở tài khoản nhân viên', async () => {
  const created = await t.api('POST', '/quan-tri/tai-khoan', {
    token: adminToken,
    body: {
      email: 'nhanvien-khoa@ocop.example',
      matKhau: 'NhanVien123',
      hoTen: 'Nhân viên kiểm tra khóa',
    },
  });

  assert.equal(created.status, 201);
  const id = created.body.id;

  const khoa = await t.api('PATCH', `/quan-tri/tai-khoan/${id}`, {
    token: adminToken,
    body: { dangHoatDong: false },
  });

  assert.equal(khoa.status, 200);
  assert.equal(khoa.body.dangHoatDong, false);

  const dangNhapBiKhoa = await t.api('POST', '/auth/dang-nhap', {
    body: {
      email: 'nhanvien-khoa@ocop.example',
      matKhau: 'NhanVien123',
    },
  });

  assert.equal(dangNhapBiKhoa.status, 403);

  const mo = await t.api('PATCH', `/quan-tri/tai-khoan/${id}`, {
    token: adminToken,
    body: { dangHoatDong: true },
  });

  assert.equal(mo.status, 200);
  assert.equal(mo.body.dangHoatDong, true);

  const dangNhapLai = await t.api('POST', '/auth/dang-nhap', {
    body: {
      email: 'nhanvien-khoa@ocop.example',
      matKhau: 'NhanVien123',
    },
  });

  assert.equal(dangNhapLai.status, 200);
});

test('Không cho quản trị viên tự khóa tài khoản của mình', async () => {
  const { rows } = await t.pool.query(
    `SELECT id FROM nguoi_dung WHERE email = $1`,
    ['quantri@ocop.example'],
  );

  const r = await t.api('PATCH', `/quan-tri/tai-khoan/${rows[0].id}`, {
    token: adminToken,
    body: { dangHoatDong: false },
  });

  assert.equal(r.status, 400);
});

test('Không cho cập nhật trạng thái với dữ liệu sai', async () => {
  const r = await t.api('PATCH', '/quan-tri/tai-khoan/1', {
    token: adminToken,
    body: { dangHoatDong: 'false' },
  });

  assert.equal(r.status, 400);
});
