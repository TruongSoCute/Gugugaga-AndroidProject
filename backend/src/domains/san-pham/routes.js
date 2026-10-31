'use strict';

const express = require('express');
const { ah } = require('../../utils/http');
const { idParam } = require('../../utils/validator');
const { phanTrang } = require('../../utils/sql');
const { parseLoc, parseTao, parseDuyet } = require('./types');

module.exports = function sanPhamRoutes({ service, auth }) {
  // ---- /san-pham: công khai cho app Client + nhập liệu/duyệt cho nhân sự ----
  const pub = express.Router();

  // GET /san-pham?vung=&hangSao=&tuKhoa=&nhaCungCapId=&trang=&kichThuoc=
  pub.get('/', ah(async (req, res) => {
    res.json(await service.danhSach(parseLoc(req.query, { quanTri: false }), phanTrang(req.query), { quanTri: false }));
  }));

  pub.get('/:id', ah(async (req, res) => {
    res.json(await service.chiTiet(idParam(req.params.id), { quanTri: false }));
  }));

  pub.post('/', auth.nhanSu, ah(async (req, res) => {
    res.status(201).json(await service.tao(parseTao(req.body), req.user.id));
  }));

  pub.patch('/:id/duyet', auth.quanTri, ah(async (req, res) => {
    const id = idParam(req.params.id);
    res.json(await service.duyet(id, parseDuyet(req.body), req.user.id));
  }));

  // ---- /quan-tri/san-pham: app Admin xem mọi trạng thái ----
  const admin = express.Router();
  admin.use(auth.nhanSu);

  admin.get('/', ah(async (req, res) => {
    res.json(await service.danhSach(parseLoc(req.query, { quanTri: true }), phanTrang(req.query), { quanTri: true }));
  }));

  admin.get('/:id', ah(async (req, res) => {
    res.json(await service.chiTiet(idParam(req.params.id), { quanTri: true }));
  }));

  return { pub, admin };
};
