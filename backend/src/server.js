'use strict';

const { loadConfig } = require('./config');
const { createPool } = require('./db');
const { createApp } = require('./app');
const { TAG } = require('./middleware/errorHandler');

const config = loadConfig();
const pool = createPool(config);
const app = createApp({ pool, config });

pool.on('error', (err) => console.error(TAG, 'Lỗi kết nối CSDL rảnh:', err.message));

const server = app.listen(config.port, () => {
  console.log(TAG, `Đang chạy ở cổng ${config.port}`);
});

// Render gửi SIGTERM khi deploy lại: đóng kết nối gọn gàng.
process.on('SIGTERM', () => {
  server.close(() => pool.end().finally(() => process.exit(0)));
});
