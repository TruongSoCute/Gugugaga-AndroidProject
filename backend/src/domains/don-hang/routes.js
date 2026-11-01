'use strict';

const express = require('express');
const { ah } = require('../../utils/http');
const { idParam } = require('../../utils/validator');
const { phanTrang } = require('../../utils/sql');
const { parseGio, parseDatHang, parseDoiTrangThai, parseLocDon } = require('./types');

module.exports = function donHangRoutes({ service, auth }) {
  // Người đang gọi API: id và có phải nhân sự không. Service dựa vào đây để kiểm tra
  // quyền sở hữu đơn và quy tắc chuyển trạng thái theo vai trò.
  const nguoi = (req) => ({ id: req.user.id, nhanSu: auth.laNhanSu(req.user) });

  // ---- /gio-hang: chỉ khách ----
  const gio = express.Router();
  gio.use(auth.khach);

  gio.get('/', ah(async (req, res) => {
    res.json(await service.gioHang(req.user.id));
  }));

  // PUT /gio-hang/:sanPhamId { soLuong }: thêm mới hoặc đặt lại số lượng.
  gio.put('/:sanPhamId', ah(async (req, res) => {
    const sanPhamId = idParam(req.params.sanPhamId, 'sanPhamId');
    res.json(await service.datVaoGio(req.user.id, sanPhamId, parseGio(req.body).soLuong));
  }));

  gio.delete('/:sanPhamId', ah(async (req, res) => {
    res.json(await service.xoaKhoiGio(req.user.id, idParam(req.params.sanPhamId, 'sanPhamId')));
  }));

  // ---- /don-hang ----
  const don = express.Router();

  // Công khai: hình thức giao và phí, để app hiển thị trước khi đặt.
  don.get('/hinh-thuc-giao', (_req, res) => {
    res.json(service.hinhThucGiao());
  });

  don.post('/', auth.khach, ah(async (req, res) => {
    res.status(201).json(await service.datHang(req.user.id, parseDatHang(req.body)));
  }));

  // Đơn của chính khách đang đăng nhập.
  don.get('/', auth.khach, ah(async (req, res) => {
    res.json(await service.dsDon(parseLocDon(req.query, { quanTri: false }), phanTrang(req.query), nguoi(req)));
  }));

  // Khách xem đơn của mình; nhân sự xem mọi đơn.
  don.get('/:id', auth.requireAuth, ah(async (req, res) => {
    res.json(await service.chiTietDon(idParam(req.params.id), nguoi(req)));
  }));

  don.patch('/:id/trang-thai', auth.requireAuth, ah(async (req, res) => {
    const n = nguoi(req);
    res.json(await service.doiTrangThai(idParam(req.params.id), parseDoiTrangThai(req.body, n), n));
  }));

  // ---- /quan-tri/don-hang: app Admin xem mọi đơn ----
  const admin = express.Router();
  admin.use(auth.nhanSu);

  admin.get('/', ah(async (req, res) => {
    res.json(await service.dsDon(parseLocDon(req.query, { quanTri: true }), phanTrang(req.query), nguoi(req)));
  }));

  admin.get('/:id', ah(async (req, res) => {
    res.json(await service.chiTietDon(idParam(req.params.id), nguoi(req)));
  }));

  return { gio, don, admin };
};
