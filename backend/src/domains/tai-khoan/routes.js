'use strict';

const express = require('express');
const { ah } = require('../../utils/http');
const { idParam } = require('../../utils/validator');
const { parseDangKy, parseDangNhap, parseTaoNhanVien, parseCapNhatTrangThai } = require('./types');

module.exports = function taiKhoanRoutes({ service, auth }) {
  //* Router dành cho đăng ký, đăng nhập và thông tin cá nhân
  const authRouter = express.Router();

  authRouter.post('/dang-ky', ah(async (req, res) => {
    res.status(201).json(
      await service.dangKy(parseDangKy(req.body)),
    );
  }));

  authRouter.post('/dang-nhap', ah(async (req, res) => {
    res.json(
      await service.dangNhap(parseDangNhap(req.body)),
    );
  }));

  authRouter.get('/toi', auth.requireAuth, ah(async (req, res) => {
    res.json(await service.thongTin(req.user.id));
  }));

  //* Router dành riêng cho quản trị viên
  const adminRouter = express.Router();

  //* Tất cả API bên dưới chỉ dành cho QUAN_TRI
  adminRouter.use(auth.quanTri);

  //* POST: Tạo tài khoản nhân viên
  adminRouter.post('/', ah(async (req, res) => {
    const data = parseTaoNhanVien(req.body);

    res.status(201).json(
      await service.taoNhanVien(data),
    );
  }));

  //* GET: Lấy danh sách tài khoản
  adminRouter.get('/', ah(async (req, res) => {
    res.json(
      await service.dsTaiKhoan(req.query),
    );
  }));

  //* PATCH: Khóa hoặc mở tài khoản
  adminRouter.patch('/:id', ah(async (req, res) => {
    const id = idParam(req.params.id, 'id');
    const data = parseCapNhatTrangThai(req.body);

    res.json(
      await service.capNhatTrangThai(
        id,
        data,
        req.user.id,
      ),
    );
  }));

  return {
    authRouter,
    adminRouter,
  };
};