'use strict';

const express = require('express');
const { ah } = require('../../utils/http');
const { parseLocDoanhSo } = require('./types');

module.exports = function baoCaoRoutes({ service, auth }) {
  const r = express.Router();
  // Báo cáo doanh số chỉ dành cho QUAN_TRI (Design_decisions.md).
  r.get('/doanh-so', auth.quanTri, ah(async (req, res) => {
    res.json(await service.doanhSo(parseLocDoanhSo(req.query)));
  }));
  return r;
};
