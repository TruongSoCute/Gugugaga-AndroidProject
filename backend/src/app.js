'use strict';

// App Wiring: nơi DUY NHẤT ghép Providers với các miền nghiệp vụ và gắn đường dẫn.
// Phụ thuộc giữa các miền (vd: sản phẩm cần chứng nhận của nhà cung cấp) được truyền
// vào ở đây, nên các miền không import trực tiếp lẫn nhau.
const express = require('express');
const cors = require('cors');
const { createProviders } = require('./providers');
const createHeThong = require('./domains/health');
const createTaiKhoan = require('./domains/accounts');
const createDanhMuc = require('./domains/sourcing-regions');
const createNhaCungCap = require('./domains/suppliers');
const createSanPham = require('./domains/products');
const createTruyXuat = require('./domains/traceability');
const createDonHang = require('./domains/orders');
const createDanhGia = require('./domains/reviews');
const createPhanAnh = require('./domains/issue-reports');
const createTuongTac = require('./domains/customer-interactions');
const createBaoCao = require('./domains/sales-reports');
const createTaiLen = require('./domains/uploads');

// storage (tùy chọn): giả lập Supabase Storage khi kiểm thử.
function createApp({ pool, config, storage }) {
  const providers = createProviders({ pool, config, storage });

  const heThong = createHeThong(providers);
  const taiKhoan = createTaiKhoan(providers);
  const danhMuc = createDanhMuc(providers);
  const nhaCungCap = createNhaCungCap(providers);
  const sanPham = createSanPham(providers, { nhaCungCap: nhaCungCap.service });
  const truyXuat = createTruyXuat(providers, { nhaCungCap: nhaCungCap.service });
  const donHang = createDonHang(providers);
  const danhGia = createDanhGia(providers);
  const phanAnh = createPhanAnh(providers);
  const tuongTac = createTuongTac(providers);
  const baoCao = createBaoCao(providers);
  const taiLen = createTaiLen(providers);

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
  app.use('/quan-tri/tai-khoan', taiKhoan.adminRouter);
  app.use('/vung-nguyen-lieu', danhMuc.vungRouter);
  app.use('/nha-cung-cap', nhaCungCap.publicRouter);
  app.use('/san-pham', sanPham.publicRouter);
  app.use('/lo-san-xuat', truyXuat.loRouter);
  app.use('/truy-xuat', truyXuat.publicRouter);
  app.use('/gio-hang', donHang.gioRouter);
  app.use('/don-hang', donHang.donRouter);
  app.use('/quan-tri/nha-cung-cap', nhaCungCap.adminRouter);
  app.use('/quan-tri/san-pham', sanPham.adminRouter);
  app.use('/quan-tri/don-hang', donHang.adminRouter);
  app.use('/cua-toi/nha-cung-cap', nhaCungCap.cuaToiRouter);
  app.use('/cua-toi/san-pham', sanPham.cuaToiRouter);
  app.use('/danh-gia', danhGia.router);
  app.use('/bao-cao-vi-pham', phanAnh.khachRouter);
  app.use('/quan-tri/bao-cao-vi-pham', phanAnh.adminRouter);
  app.use('/yeu-thich', tuongTac.yeuThichRouter);
  app.use('/theo-doi', tuongTac.theoDoiRouter);
  app.use('/bao-cao', baoCao.router);
  app.use('/tai-len', taiLen.router);

  app.use(providers.http.notFoundHandler);
  app.use(providers.http.errorHandler);
  return app;
}

module.exports = { createApp };
