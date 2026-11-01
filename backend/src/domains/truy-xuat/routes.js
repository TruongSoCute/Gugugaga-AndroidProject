'use strict';

const express = require('express');
const { ah } = require('../../utils/http');
const { idParam } = require('../../utils/validator');
const { phanTrang } = require('../../utils/sql');
const { parseTaoLo, parseBuoc, parseLocLo, chuanHoaMa } = require('./types');

module.exports = function truyXuatRoutes({ service, auth, http, config }) {
  // Nội dung in trên QR: đường dẫn tới API truy xuất công khai của đúng lô.
  // App Client đọc đoạn cuối đường dẫn để lấy mã rồi gọi GET /truy-xuat/:ma.
  const themDuongDan = (req, lo) => ({
    ...lo,
    duongDanTruyXuat: `${http.baseUrl(config, req)}/truy-xuat/${lo.maTruyXuat}`,
  });
  // Giữ thứ tự khóa JSON như trước: cacBuoc nằm cuối.
  const loJson = (req, { cacBuoc, ...lo }) => ({ ...themDuongDan(req, lo), cacBuoc });

  // ---- /lo-san-xuat: quản lý lô, chỉ nhân sự ----
  const lo = express.Router();
  lo.use(auth.nhanSu);

  lo.get('/', ah(async (req, res) => {
    res.json(await service.dsLo(parseLocLo(req.query), phanTrang(req.query)));
  }));

  lo.get('/:id', ah(async (req, res) => {
    res.json(loJson(req, await service.chiTietLo(idParam(req.params.id))));
  }));

  lo.post('/', ah(async (req, res) => {
    res.status(201).json(loJson(req, await service.taoLo(parseTaoLo(req.body), req.user.id)));
  }));

  lo.post('/:id/buoc', ah(async (req, res) => {
    const loId = idParam(req.params.id);
    res.status(201).json(await service.themBuoc(loId, parseBuoc(req.body)));
  }));

  // ---- /truy-xuat/:ma: CÔNG KHAI, không cần JWT ----
  const congKhai = express.Router();
  congKhai.get('/:ma', ah(async (req, res) => {
    res.json(await service.truyXuatCongKhai(chuanHoaMa(req.params.ma)));
  }));

  return { lo, congKhai };
};
