'use strict';

const express = require('express');
const { ah } = require('../../utils/http');
const { idParam } = require('../../utils/validator');
const { phanTrang } = require('../../utils/sql');
const { parseGuiPhanAnh, parseXuLy, parseLoc } = require('./types');

module.exports = function phanAnhRoutes({ service, auth }) {
  const nguoi = (req) => ({ id: req.user.id, nhanSu: auth.laNhanSu(req.user) });

  // ---- /bao-cao-vi-pham: khách gửi và xem phản ánh của mình ----
  const khach = express.Router();
  khach.use(auth.khach);

  khach.post('/', ah(async (req, res) => {
    res.status(201).json(await service.gui(req.user.id, parseGuiPhanAnh(req.body)));
  }));

  khach.get('/', ah(async (req, res) => {
    res.json(await service.ds(parseLoc(req.query), phanTrang(req.query), nguoi(req)));
  }));

  khach.get('/:id', ah(async (req, res) => {
    res.json(await service.chiTiet(idParam(req.params.id), nguoi(req)));
  }));

  // ---- /quan-tri/bao-cao-vi-pham: nhân sự xem và xử lý ----
  const admin = express.Router();
  admin.use(auth.nhanSu);

  admin.get('/', ah(async (req, res) => {
    res.json(await service.ds(parseLoc(req.query), phanTrang(req.query), nguoi(req)));
  }));

  admin.get('/:id', ah(async (req, res) => {
    res.json(await service.chiTiet(idParam(req.params.id), nguoi(req)));
  }));

  admin.patch('/:id', ah(async (req, res) => {
    res.json(await service.xuLy(idParam(req.params.id), parseXuLy(req.body), req.user.id));
  }));

  return { khach, admin };
};
