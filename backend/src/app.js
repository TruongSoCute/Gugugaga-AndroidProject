'use strict';

// App Wiring: nơi DUY NHẤT ghép Providers với các miền nghiệp vụ và gắn đường dẫn.
// Phụ thuộc giữa các miền (vd: sản phẩm cần chứng nhận của nhà cung cấp) được truyền
// vào ở đây, nên các miền không import trực tiếp lẫn nhau.
const express = require('express');
const cors = require('cors');
const { createProviders } = require('./providers');
const createHeThong = require('./domains/he-thong');
const createTaiKhoan = require('./domains/tai-khoan');
const createDanhMuc = require('./domains/danh-muc');
const createNhaCungCap = require('./domains/nha-cung-cap');
const createSanPham = require('./domains/san-pham');
const createTruyXuat = require('./domains/truy-xuat');

function createApp({ pool, config }) {
  const providers = createProviders({ pool, config });

  const heThong = createHeThong(providers);
  const taiKhoan = createTaiKhoan(providers);
  const danhMuc = createDanhMuc(providers);
  const nhaCungCap = createNhaCungCap(providers);
  const sanPham = createSanPham(providers, { nhaCungCap: nhaCungCap.service });
  const truyXuat = createTruyXuat(providers, { nhaCungCap: nhaCungCap.service });

  const app = express();
  app.disable('x-powered-by');
  // Render đặt backend sau proxy HTTPS; cần để req.protocol trả "https".
  app.set('trust proxy', 1);
  app.use(cors());
  app.use(express.json({ limit: '100kb' }));

  app.get('/', (_req, res) => {
    res.json({ ten: 'OCOP API – đề 05', suKhoe: '/health', taiLieu: 'docs/development/API.md' });
  });
  app.use('/health', heThong.healthRouter);
  app.use('/auth', taiKhoan.authRouter);
  app.use('/vung-nguyen-lieu', danhMuc.vungRouter);
  app.use('/nha-cung-cap', nhaCungCap.publicRouter);
  app.use('/san-pham', sanPham.publicRouter);
  app.use('/lo-san-xuat', truyXuat.loRouter);
  app.use('/truy-xuat', truyXuat.publicRouter);
  app.use('/quan-tri/nha-cung-cap', nhaCungCap.adminRouter);
  app.use('/quan-tri/san-pham', sanPham.adminRouter);

  app.use(providers.http.notFoundHandler);
  app.use(providers.http.errorHandler);
  return app;
}

module.exports = { createApp };
