'use strict';

const express = require('express');
const { ah } = require('../../utils/http');

module.exports = function danhMucRoutes({ service }) {
  const r = express.Router();
  // Công khai: danh sách vùng nguyên liệu để lọc sản phẩm.
  r.get('/', ah(async (_req, res) => {
    res.json(await service.dsVung());
  }));
  return r;
};
