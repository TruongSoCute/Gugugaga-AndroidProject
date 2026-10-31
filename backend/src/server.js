'use strict';

const { loadConfig } = require('./config');
const { createPool } = require('./providers/db');
const { logger } = require('./providers/logger');
const { createApp } = require('./app');

const config = loadConfig();
const pool = createPool(config);
const app = createApp({ pool, config });

pool.on('error', (err) => logger.error('Lỗi kết nối CSDL rảnh:', err.message));

const server = app.listen(config.port, () => {
  logger.info(`Đang chạy ở cổng ${config.port}`);
});

// Render gửi SIGTERM khi deploy lại: đóng kết nối gọn gàng.
process.on('SIGTERM', () => {
  server.close(() => pool.end().finally(() => process.exit(0)));
});
