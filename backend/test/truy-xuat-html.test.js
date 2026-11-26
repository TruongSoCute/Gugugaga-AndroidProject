'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const http = require('node:http');
const express = require('express');
const truyXuatRoutes = require('../src/domains/truy-xuat/routes');
const { escapeHtml, renderTruyXuatHtml } = require('../src/domains/truy-xuat/types');
const { notFound } = require('../src/utils/errors');

function taoApp(duLieuMau) {
  const app = express();
  const router = truyXuatRoutes({
    service: {
      async truyXuatCongKhai(ma) {
        if (ma !== 'B056FB25CA6642785532') {
          throw notFound('Không tìm thấy lô với mã truy xuất này hoặc lô chưa được công bố.');
        }
        return duLieuMau;
      },
    },
    auth: { nhanSu: (_req, _res, next) => next() },
    http: { baseUrl: () => 'https://ocop-backend.onrender.com' },
    config: {},
  });
  app.use('/truy-xuat', router.congKhai);
  app.use((err, _req, res, _next) => res.status(err.status || 500).json({ loi: { ma: err.ma || 'LOI', thongDiep: err.message } }));
  return app;
}

async function goi(app, path, accept) {
  const server = http.createServer(app);
  await new Promise((r) => server.listen(0, '127.0.0.1', r));
  try {
    const { port } = server.address();
    const headers = accept ? { Accept: accept } : {};
    const res = await fetch(`http://127.0.0.1:${port}${path}`, { headers });
    return {
      status: res.status,
      contentType: res.headers.get('content-type') || '',
      text: await res.text(),
    };
  } finally {
    await new Promise((r) => server.close(r));
  }
}

const MAU = {
  maTruyXuat: 'B056FB25CA6642785532',
  lo: {
    ngaySanXuat: '2026-03-02',
    hanSuDung: '2027-03-02',
    nguoiSanXuat: 'Tổ <script>alert(1)</script>',
    anhHienTruongUrl: 'https://example.com/lo.jpg',
    vungNguyenLieu: { id: 1, ten: 'Cần Giờ & "Biển"', moTa: 'Vùng ngập mặn' },
  },
  sanPham: {
    id: 1,
    ten: 'Khô cá dứa <img src=x onerror=alert(2)>',
    moTa: 'Đặc sản',
    donViTinh: 'gói',
    hangSao: 4,
    anhUrl: 'javascript:alert(3)',
  },
  nhaCungCap: {
    id: 1,
    ten: 'HTX Cá Dứa',
    diaChi: 'Ấp 1',
    vung: 'Cần Giờ',
    anhCoSoUrl: 'https://example.com/ncc.jpg',
    chungNhan: [{ loai: 'OCOP', soHieu: 'CN-01', ngayHetHan: '2028-01-01' }],
  },
  cacBuoc: [
    { thuTu: 1, tenBuoc: 'Đánh bắt', thoiDiem: '2026-03-02T06:00:00Z', moTa: 'Tại cửa biển', anhUrl: 'https://example.com/b1.jpg' },
  ],
};

test('escapeHtml chặn các ký tự nguy hiểm XSS', () => {
  assert.equal(escapeHtml('<script>"\'&</script>'), '&lt;script&gt;&quot;&#39;&amp;&lt;/script&gt;');
});

test('GET /truy-xuat/:ma trả JSON khi Accept: application/json hoặc mặc định */*', async () => {
  const app = taoApp(MAU);
  const r1 = await goi(app, '/truy-xuat/B056FB25CA6642785532', 'application/json');
  assert.equal(r1.status, 200);
  assert.match(r1.contentType, /application\/json/);
  assert.equal(JSON.parse(r1.text).maTruyXuat, 'B056FB25CA6642785532');

  const r2 = await goi(app, '/truy-xuat/B056FB25CA6642785532', '*/*');
  assert.equal(r2.status, 200);
  assert.match(r2.contentType, /application\/json/);
});

test('GET /truy-xuat/:ma trả HTML khi trình duyệt gửi Accept: text/html và escape XSS', async () => {
  const app = taoApp(MAU);
  const r = await goi(app, '/truy-xuat/B056FB25CA6642785532', 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8');
  assert.equal(r.status, 200);
  assert.match(r.contentType, /text\/html/);
  assert.match(r.text, /Đã xác minh nguồn gốc OCOP/);
  assert.match(r.text, /&lt;script&gt;alert\(1\)&lt;\/script&gt;/);
  assert.equal(r.text.includes('<script>alert(1)</script>'), false);
  assert.equal(r.text.includes('onerror=alert(2)>'), false);
  assert.equal(r.text.includes('javascript:alert(3)'), false);
});

test('GET /truy-xuat/:ma với mã sai + Accept: text/html trả 404 HTML và escape mã', async () => {
  const app = taoApp(MAU);
  const r = await goi(app, '/truy-xuat/%3Cscript%3Ex%3C%2Fscript%3E', 'text/html');
  assert.equal(r.status, 404);
  assert.match(r.contentType, /text\/html/);
  assert.match(r.text, /Không xác minh được nguồn gốc/);
  assert.equal(r.text.includes('<script>x</script>'), false);
});

test('renderTruyXuatHtml xử lý danh sách bước rỗng', () => {
  const html = renderTruyXuatHtml({ ...MAU, cacBuoc: [] });
  assert.match(html, /Chưa có bước truy xuất nào/);
});
