'use strict';

const express = require('express');
const cors = require('cors');
const { errorHandler } = require('./middleware/errorHandler');
const { HttpError } = require('./errors');

// Tạo ứng dụng Express từ pool CSDL và cấu hình (tách khỏi server.js để kiểm thử).
function createApp({ pool, config }) {
  const ctx = { pool, config };
  const app = express();

  app.disable('x-powered-by');
  // Render đặt backend sau proxy HTTPS; cần để req.protocol trả "https".
  app.set('trust proxy', 1);
  app.use(cors());
  app.use(express.json({ limit: '100kb' }));

  const nhaCungCap = require('./routes/nhaCungCap')(ctx);
  const sanPham = require('./routes/sanPham')(ctx);

  app.get('/', (_req, res) => {
    res.json({ ten: 'OCOP API – đề 05', suKhoe: '/health', taiLieu: 'docs/development/API.md' });
  });
  app.use('/health', require('./routes/health')(ctx));
  app.use('/auth', require('./routes/auth')(ctx));
  app.use('/vung-nguyen-lieu', require('./routes/vung')(ctx));
  app.use('/nha-cung-cap', nhaCungCap.pub);
  app.use('/san-pham', sanPham.pub);
  app.use('/lo-san-xuat', require('./routes/loSanXuat')(ctx));
  app.use('/truy-xuat', require('./routes/truyXuat')(ctx));
  app.use('/quan-tri/nha-cung-cap', nhaCungCap.admin);
  app.use('/quan-tri/san-pham', sanPham.admin);

  app.use((req, _res, next) => {
    next(new HttpError(404, 'KHONG_TIM_THAY_DUONG_DAN', `Không có API ${req.method} ${req.path}.`));
  });
  app.use(errorHandler);
  return app;
}

module.exports = { createApp };
