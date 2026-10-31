'use strict';

const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');
const jwt = require('jsonwebtoken');
const { setup } = require('./helpers');

let t;
before(async () => { t = await setup(); });
after(async () => { await t.teardown(); });

test('GET /health trả 200 và CSDL ok', async () => {
  const r = await t.api('GET', '/health');
  assert.equal(r.status, 200);
  assert.equal(r.body.trangThai, 'ok');
  assert.equal(r.body.csdl, 'ok');
});

test('Đăng nhập đúng trả token và không trả mật khẩu', async () => {
  const r = await t.api('POST', '/auth/dang-nhap', { body: { email: 'QuanTri@ocop.example', matKhau: 'Demo@12345' } });
  assert.equal(r.status, 200);
  assert.ok(r.body.token);
  assert.equal(r.body.nguoiDung.vaiTro, 'QUAN_TRI');
  assert.equal(JSON.stringify(r.body).includes('matKhau'), false);
  assert.equal(JSON.stringify(r.body).includes('$2b$'), false);
});

test('Đăng nhập sai mật khẩu hoặc email không tồn tại trả 401 cùng thông điệp', async () => {
  const a = await t.api('POST', '/auth/dang-nhap', { body: { email: 'khach1@ocop.example', matKhau: 'sai-mat-khau' } });
  const b = await t.api('POST', '/auth/dang-nhap', { body: { email: 'khong-co@ocop.example', matKhau: 'sai-mat-khau' } });
  assert.equal(a.status, 401);
  assert.equal(b.status, 401);
  assert.deepEqual(a.body, b.body);
});

test('Đăng nhập thiếu dữ liệu trả 400 kèm chi tiết trường', async () => {
  const r = await t.api('POST', '/auth/dang-nhap', { body: { email: 'abc' } });
  assert.equal(r.status, 400);
  const truong = r.body.loi.chiTiet.map((x) => x.truong).sort();
  assert.deepEqual(truong, ['email', 'matKhau']);
});

test('JSON hỏng trả 400', async () => {
  const r = await t.api('POST', '/auth/dang-nhap', { body: '{"email":' });
  assert.equal(r.status, 400);
  assert.equal(r.body.loi.ma, 'JSON_KHONG_HOP_LE');
});

test('Đăng ký luôn tạo vai trò KHACH dù client gửi vaiTro khác', async () => {
  const r = await t.api('POST', '/auth/dang-ky', {
    body: { email: 'moi@ocop.example', matKhau: 'MatKhau123', hoTen: 'Người mới', vaiTro: 'QUAN_TRI' },
  });
  assert.equal(r.status, 201);
  assert.equal(r.body.nguoiDung.vaiTro, 'KHACH');
  const { rows } = await t.pool.query("SELECT vai_tro, mat_khau_hash FROM nguoi_dung WHERE email = 'moi@ocop.example'");
  assert.equal(rows[0].vai_tro, 'KHACH');
  assert.match(rows[0].mat_khau_hash, /^\$2[aby]\$10\$/, 'mật khẩu phải được băm bằng bcrypt');

  const dup = await t.api('POST', '/auth/dang-ky', {
    body: { email: 'MOI@ocop.example', matKhau: 'MatKhau123', hoTen: 'Trùng' },
  });
  assert.equal(dup.status, 409);
  assert.equal(dup.body.loi.ma, 'EMAIL_DA_TON_TAI');
});

test('Đăng ký với mật khẩu ngắn trả 400', async () => {
  const r = await t.api('POST', '/auth/dang-ky', { body: { email: 'a@b.vn', matKhau: '123', hoTen: 'A' } });
  assert.equal(r.status, 400);
});

test('GET /auth/toi: thiếu token 401, token giả 401, token hết hạn 401', async () => {
  assert.equal((await t.api('GET', '/auth/toi')).status, 401);
  assert.equal((await t.api('GET', '/auth/toi', { token: 'abc.def.ghi' })).status, 401);
  const fake = jwt.sign({ sub: '1', vaiTro: 'QUAN_TRI' }, 'khoa-sai-khong-phai-cua-server-0123456789');
  assert.equal((await t.api('GET', '/auth/toi', { token: fake })).status, 401);
  const expired = jwt.sign({ sub: '1', vaiTro: 'QUAN_TRI', exp: Math.floor(Date.now() / 1000) - 10 }, t.config.jwtSecret);
  const r = await t.api('GET', '/auth/toi', { token: expired });
  assert.equal(r.status, 401);
  assert.equal(r.body.loi.ma, 'TOKEN_HET_HAN');
});

test('Vai trò lấy từ CSDL: token ghi QUAN_TRI của khách vẫn bị 403', async () => {
  const { rows } = await t.pool.query("SELECT id FROM nguoi_dung WHERE email = 'khach1@ocop.example'");
  const forged = jwt.sign({ sub: String(rows[0].id), vaiTro: 'QUAN_TRI' }, t.config.jwtSecret);
  const r = await t.api('GET', '/quan-tri/san-pham', { token: forged });
  assert.equal(r.status, 403);
});

test('Tài khoản bị khóa không dùng được token cũ', async () => {
  const token = await t.login('khach5@ocop.example');
  await t.pool.query("UPDATE nguoi_dung SET dang_hoat_dong = FALSE WHERE email = 'khach5@ocop.example'");
  assert.equal((await t.api('GET', '/auth/toi', { token })).status, 401);
  const r = await t.api('POST', '/auth/dang-nhap', { body: { email: 'khach5@ocop.example', matKhau: 'Demo@12345' } });
  assert.equal(r.status, 403);
});

test('Đường dẫn không tồn tại trả 404 JSON', async () => {
  const r = await t.api('GET', '/khong-co');
  assert.equal(r.status, 404);
  assert.equal(r.body.loi.ma, 'KHONG_TIM_THAY_DUONG_DAN');
});
