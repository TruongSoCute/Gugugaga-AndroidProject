'use strict';

const express = require('express');
const { ah, camel } = require('../utils');

module.exports = function vungRouter({ pool }) {
  const r = express.Router();

  // Công khai: danh sách vùng nguyên liệu để lọc sản phẩm.
  r.get('/', ah(async (_req, res) => {
    const { rows } = await pool.query(
      'SELECT id, ten, mo_ta, vi_do, kinh_do FROM vung_nguyen_lieu ORDER BY id',
    );
    res.json(rows.map(camel));
  }));

  return r;
};
