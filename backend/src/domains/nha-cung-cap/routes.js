'use strict';

// Tầng routes (Runtime + UI của backend): đọc request -> kiểm tra bằng types ->
// gọi service -> trả JSON. Không chứa SQL hay quy tắc nghiệp vụ.
const express = require('express');
const { ah } = require('../../utils/http');
const { idParam } = require('../../utils/validator');
const { phanTrang } = require('../../utils/sql');
const { parseTaoHoSo, parseDuyet, parseLocCongKhai, parseLocQuanTri } = require('./types');

module.exports = function nhaCungCapRoutes({ service, auth }) {
  // ---- /nha-cung-cap: công khai (chỉ hồ sơ đã duyệt) + thao tác nhập liệu/duyệt ----
  const pub = express.Router();

  pub.get('/', ah(async (req, res) => {
    res.json(await service.dsCongKhai(parseLocCongKhai(req.query)));
  }));

  pub.get('/:id', ah(async (req, res) => {
    res.json(await service.chiTietCongKhai(idParam(req.params.id)));
  }));

  pub.post('/', auth.nhanSu, ah(async (req, res) => {
    res.status(201).json(await service.taoHoSo(parseTaoHoSo(req.body), req.user.id));
  }));

  pub.patch('/:id/duyet', auth.quanTri, ah(async (req, res) => {
    const id = idParam(req.params.id);
    res.json(await service.duyet(id, parseDuyet(req.body), req.user.id));
  }));

  // ---- /quan-tri/nha-cung-cap: app Admin xem mọi trạng thái ----
  const admin = express.Router();
  admin.use(auth.nhanSu);

  admin.get('/', ah(async (req, res) => {
    res.json(await service.dsQuanTri(parseLocQuanTri(req.query), phanTrang(req.query)));
  }));

  admin.get('/:id', ah(async (req, res) => {
    res.json(await service.chiTietQuanTri(idParam(req.params.id)));
  }));

  return { pub, admin };
};
