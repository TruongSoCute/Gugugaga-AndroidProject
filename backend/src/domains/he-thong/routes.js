'use strict';

const express = require('express');

// GET /health: dùng khi demo và để đánh thức Render. Không cần đăng nhập,
// không trả thông tin bí mật.
module.exports = function heThongRoutes({ service }) {
  const r = express.Router();
  r.get('/', async (_req, res) => {
    const { ok, ketQua } = await service.kiemTraSucKhoe();
    res.status(ok ? 200 : 503).json(ketQua);
  });
  return r;
};
