'use strict';

const express = require('express');

// GET /health: kiểm tra backend đang chạy và kết nối được CSDL (dùng khi demo
// và để đánh thức Render). Không cần đăng nhập, không trả thông tin bí mật.
module.exports = function healthRouter({ pool }) {
  const r = express.Router();
  r.get('/', async (_req, res) => {
    try {
      await pool.query('SELECT 1');
      res.json({ trangThai: 'ok', csdl: 'ok', thoiGian: new Date().toISOString() });
    } catch {
      res.status(503).json({ trangThai: 'loi', csdl: 'khong_ket_noi_duoc', thoiGian: new Date().toISOString() });
    }
  });
  return r;
};
