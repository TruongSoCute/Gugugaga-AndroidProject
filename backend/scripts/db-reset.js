'use strict';

// Chạy schema.sql rồi seed.sql trên DATABASE_URL. XÓA TOÀN BỘ DỮ LIỆU HIỆN CÓ.
// Cách dùng: npm run db:reset -- --yes
const fs = require('node:fs');
const path = require('node:path');
require('dotenv').config({ quiet: true });
const { createPool } = require('../src/providers/db');

async function main() {
  if (!process.argv.includes('--yes')) {
    console.error('Lệnh này xóa và tạo lại toàn bộ bảng. Chạy lại với --yes nếu chắc chắn.');
    process.exit(1);
  }
  if (!process.env.DATABASE_URL) {
    console.error('Thiếu DATABASE_URL.');
    process.exit(1);
  }
  const pool = createPool({
    databaseUrl: process.env.DATABASE_URL,
    databaseSsl: process.env.DATABASE_SSL === 'true',
    databaseCaCert: process.env.DATABASE_CA_CERT || null,
    databasePoolMax: 1,
  });
  try {
    for (const file of ['schema.sql', 'seed.sql']) {
      const sql = fs.readFileSync(path.join(__dirname, '..', 'db', file), 'utf8');
      await pool.query(sql);
      console.log(`Đã chạy ${file}`);
    }
  } finally {
    await pool.end();
  }
}

main().catch((err) => {
  console.error(err.message);
  process.exit(1);
});
