'use strict';

const express = require('express');
const bcrypt = require('bcryptjs');
const { validate } = require('../validator');
const { HttpError } = require('../errors');
const { ah, camel } = require('../utils');
const { signToken, requireAuth, VAI_TRO } = require('../middleware/auth');

const BCRYPT_COST = 10;
// Hash giả để so sánh khi email không tồn tại, giúp thời gian phản hồi tương đương
// và không lộ email nào đã đăng ký.
const DUMMY_HASH = bcrypt.hashSync('khong-phai-mat-khau-that', BCRYPT_COST);

const publicUser = (u) => camel({
  id: u.id, email: u.email, ho_ten: u.ho_ten, so_dien_thoai: u.so_dien_thoai, vai_tro: u.vai_tro,
});

module.exports = function authRouter(ctx) {
  const { pool, config } = ctx;
  const r = express.Router();

  // Khách tự đăng ký. Vai trò luôn là KHACH, bỏ qua mọi trường vaiTro client gửi.
  r.post('/dang-ky', ah(async (req, res) => {
    const d = validate(req.body)
      .email('email', { required: true })
      .password('matKhau')
      .string('hoTen', { required: true, max: 120 })
      .phone('soDienThoai')
      .done();
    const hash = await bcrypt.hash(d.matKhau, BCRYPT_COST);
    let user;
    try {
      const { rows } = await pool.query(
        `INSERT INTO nguoi_dung (email, mat_khau_hash, ho_ten, so_dien_thoai, vai_tro)
         VALUES ($1, $2, $3, $4, $5)
         RETURNING id, email, ho_ten, so_dien_thoai, vai_tro`,
        [d.email, hash, d.hoTen, d.soDienThoai || null, VAI_TRO.KHACH],
      );
      user = rows[0];
    } catch (err) {
      if (err.code === '23505') throw new HttpError(409, 'EMAIL_DA_TON_TAI', 'Email đã được đăng ký.');
      throw err;
    }
    res.status(201).json({ token: signToken(config, user), nguoiDung: publicUser(user) });
  }));

  r.post('/dang-nhap', ah(async (req, res) => {
    const d = validate(req.body)
      .email('email', { required: true })
      .string('matKhau', { required: true, max: 200 })
      .done();
    const { rows } = await pool.query(
      `SELECT id, email, mat_khau_hash, ho_ten, so_dien_thoai, vai_tro, dang_hoat_dong
       FROM nguoi_dung WHERE email = $1`,
      [d.email],
    );
    const user = rows[0];
    const ok = await bcrypt.compare(req.body.matKhau, user ? user.mat_khau_hash : DUMMY_HASH);
    if (!user || !ok) {
      throw new HttpError(401, 'SAI_THONG_TIN_DANG_NHAP', 'Email hoặc mật khẩu không đúng.');
    }
    if (!user.dang_hoat_dong) {
      throw new HttpError(403, 'TAI_KHOAN_BI_KHOA', 'Tài khoản đã bị khóa.');
    }
    res.json({ token: signToken(config, user), nguoiDung: publicUser(user) });
  }));

  r.get('/toi', requireAuth(ctx), ah(async (req, res) => {
    const { rows } = await pool.query(
      'SELECT id, email, ho_ten, so_dien_thoai, vai_tro FROM nguoi_dung WHERE id = $1',
      [req.user.id],
    );
    res.json(publicUser(rows[0]));
  }));

  return r;
};
