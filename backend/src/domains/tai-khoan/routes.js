'use strict';

const express = require('express');
const { ah } = require('../../utils/http');
const { parseDangKy, parseDangNhap } = require('./types');

module.exports = function taiKhoanRoutes({ service, auth }) {
  const r = express.Router();

  r.post('/dang-ky', ah(async (req, res) => {
    res.status(201).json(await service.dangKy(parseDangKy(req.body)));
  }));

  r.post('/dang-nhap', ah(async (req, res) => {
    res.json(await service.dangNhap(parseDangNhap(req.body)));
  }));

  r.get('/toi', auth.requireAuth, ah(async (req, res) => {
    res.json(await service.thongTin(req.user.id));
  }));

  return r;
};
