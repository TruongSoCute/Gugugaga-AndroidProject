'use strict';

const { camel } = require('../../utils/sql');

async function dsVung(q) {
  const { rows } = await q.query('SELECT id, ten, mo_ta, vi_do, kinh_do FROM vung_nguyen_lieu ORDER BY id');
  return rows.map(camel);
}

module.exports = { dsVung };
