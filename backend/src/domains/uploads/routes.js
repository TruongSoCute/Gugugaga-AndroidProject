'use strict';

const express = require('express');
const { ah } = require('../../utils/http');
const { HttpError } = require('../../utils/errors');
const { KICH_THUOC_TOI_DA } = require('./types');

module.exports = function taiLenRoutes({ service, auth }) {
  const r = express.Router();

  // POST /tai-len/anh?mucDich=danh-gia, body là byte của ảnh (Content-Type: image/jpeg|png|webp).
  // Mọi tài khoản đã đăng nhập đều tải được (khách: ảnh đánh giá; nhà cung cấp: ảnh sản phẩm; nhân sự: ảnh lô).
  r.post(
    '/anh',
    auth.requireAuth,
    express.raw({ type: ['image/jpeg', 'image/png', 'image/webp'], limit: KICH_THUOC_TOI_DA }),
    ah(async (req, res) => {
      if (!Buffer.isBuffer(req.body) || req.body.length === 0) {
        throw new HttpError(415, 'KHONG_PHAI_ANH', 'Gửi ảnh với Content-Type image/jpeg, image/png hoặc image/webp.');
      }
      res.status(201).json(await service.taiAnh(req.body, String(req.query.mucDich || ''), req.user.id));
    }),
  );

  return r;
};
