'use strict';

const { Pool, types } = require('pg');

// BIGINT (giá tiền, count) trả về dạng chuỗi theo mặc định; giá trị của hệ thống
// nhỏ hơn 2^53 nên chuyển sang Number để app nhận số.
types.setTypeParser(20, (v) => Number(v));
// NUMERIC (tọa độ, trung bình sao) -> Number.
types.setTypeParser(1700, (v) => Number(v));
// DATE giữ nguyên chuỗi 'YYYY-MM-DD' để tránh lệch ngày do múi giờ.
types.setTypeParser(1082, (v) => v);

function createPool(config) {
  let ssl = false;
  if (config.databaseSsl) {
    ssl = config.databaseCaCert
      ? { ca: config.databaseCaCert, rejectUnauthorized: true }
      : { rejectUnauthorized: false };
  }
  return new Pool({
    connectionString: config.databaseUrl,
    ssl,
    max: config.databasePoolMax,
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 10000,
  });
}

// Chạy fn(client) trong một transaction: mọi câu lệnh cùng thành công (COMMIT)
// hoặc cùng bị hoàn tác (ROLLBACK) nếu có lỗi.
async function withTransaction(pool, fn) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const result = await fn(client);
    await client.query('COMMIT');
    return result;
  } catch (err) {
    await client.query('ROLLBACK').catch(() => {});
    throw err;
  } finally {
    client.release();
  }
}

module.exports = { createPool, withTransaction };
