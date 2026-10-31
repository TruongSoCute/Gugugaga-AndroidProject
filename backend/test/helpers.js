'use strict';

// Khởi tạo môi trường kiểm thử: chạy lại schema.sql + seed.sql trên TEST_DATABASE_URL
// (CSDL riêng cho test, sẽ bị xóa), rồi chạy app ở cổng ngẫu nhiên.
const fs = require('node:fs');
const path = require('node:path');
require('dotenv').config({ quiet: true, path: path.join(__dirname, '..', '.env') });
const { createPool } = require('../src/providers/db');
const { createApp } = require('../src/app');

async function setup() {
  const databaseUrl = process.env.TEST_DATABASE_URL;
  if (!databaseUrl) {
    throw new Error('Cần đặt TEST_DATABASE_URL (CSDL riêng cho test, sẽ bị xóa dữ liệu).');
  }
  if (process.env.DATABASE_URL && process.env.DATABASE_URL === databaseUrl) {
    throw new Error('TEST_DATABASE_URL phải khác DATABASE_URL để không xóa dữ liệu thật.');
  }
  const config = {
    port: 0,
    databaseUrl,
    databaseSsl: process.env.TEST_DATABASE_SSL === 'true',
    databaseCaCert: null,
    databasePoolMax: 5,
    jwtSecret: 'test-secret-chi-dung-cho-kiem-thu-tu-dong-0123456789',
    jwtExpiresIn: '1h',
    publicBaseUrl: 'https://ocop.example',
  };
  const pool = createPool(config);
  for (const file of ['schema.sql', 'seed.sql']) {
    await pool.query(fs.readFileSync(path.join(__dirname, '..', 'db', file), 'utf8'));
  }
  const app = createApp({ pool, config });
  const server = await new Promise((resolve) => {
    const s = app.listen(0, () => resolve(s));
  });
  const base = `http://127.0.0.1:${server.address().port}`;

  async function api(method, url, { token, body, headers = {} } = {}) {
    const res = await fetch(base + url, {
      method,
      headers: {
        ...(body !== undefined ? { 'content-type': 'application/json' } : {}),
        ...(token ? { authorization: `Bearer ${token}` } : {}),
        ...headers,
      },
      body: body === undefined ? undefined : typeof body === 'string' ? body : JSON.stringify(body),
    });
    const text = await res.text();
    let json;
    try { json = text ? JSON.parse(text) : undefined; } catch { json = text; }
    return { status: res.status, body: json };
  }

  async function login(email, matKhau = 'Demo@12345') {
    const r = await api('POST', '/auth/dang-nhap', { body: { email, matKhau } });
    if (r.status !== 200) throw new Error(`Đăng nhập ${email} thất bại: ${r.status}`);
    return r.body.token;
  }

  async function teardown() {
    await new Promise((resolve) => server.close(resolve));
    await pool.end();
  }

  return { api, login, pool, config, teardown };
}

module.exports = { setup };
