'use strict';

const express = require('express');
const { ah } = require('../../utils/http');
const { phanTrang } = require('../../utils/sql');
const { parseDanhGia, parseLocDanhGia } = require('./types');

module.exports = function danhGiaRoutes({ service, auth }) {
  const r = express.Router();

  // Công khai: đánh giá của một sản phẩm, mới nhất trước, kèm điểm trung bình.
  r.get('/', ah(async (req, res) => {
    res.json(await service.dsTheoSanPham(parseLocDanhGia(req.query).sanPhamId, phanTrang(req.query)));
  }));

  r.post('/', auth.khach, ah(async (req, res) => {
    res.status(201).json(await service.danhGia(req.user.id, parseDanhGia(req.body)));
  }));

  return r;
};
