'use strict';

const express = require('express');
const { ah } = require('../../utils/http');
const { idParam } = require('../../utils/validator');

module.exports = function tuongTacRoutes({ service, auth }) {
  // ---- /yeu-thich: sản phẩm yêu thích của khách ----
  const yeuThich = express.Router();
  yeuThich.use(auth.khach);
  yeuThich.get('/', ah(async (req, res) => { res.json(await service.dsYeuThich(req.user.id)); }));
  yeuThich.put('/:sanPhamId', ah(async (req, res) => {
    res.json(await service.yeuThich(req.user.id, idParam(req.params.sanPhamId, 'sanPhamId')));
  }));
  yeuThich.delete('/:sanPhamId', ah(async (req, res) => {
    res.json(await service.boYeuThich(req.user.id, idParam(req.params.sanPhamId, 'sanPhamId')));
  }));

  // ---- /theo-doi: nhà cung cấp khách theo dõi ----
  const theoDoi = express.Router();
  theoDoi.use(auth.khach);
  theoDoi.get('/', ah(async (req, res) => { res.json(await service.dsTheoDoi(req.user.id)); }));
  theoDoi.put('/:nhaCungCapId', ah(async (req, res) => {
    res.json(await service.theoDoi(req.user.id, idParam(req.params.nhaCungCapId, 'nhaCungCapId')));
  }));
  theoDoi.delete('/:nhaCungCapId', ah(async (req, res) => {
    res.json(await service.boTheoDoi(req.user.id, idParam(req.params.nhaCungCapId, 'nhaCungCapId')));
  }));

  return { yeuThich, theoDoi };
};
