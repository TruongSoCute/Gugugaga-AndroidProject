'use strict';

const { withApiColumns, camel } = require('../../utils/sql');

async function dsVung(q) {
  const { rows } = withApiColumns(await q.query('SELECT id, name, description, latitude, longitude FROM sourcing_regions ORDER BY id'));
  return rows.map(camel);
}

module.exports = { dsVung };
