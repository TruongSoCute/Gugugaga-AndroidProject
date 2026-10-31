'use strict';

const repo = require('./repo');

module.exports = function createDanhMucService({ db }) {
  return {
    dsVung: () => repo.dsVung(db),
  };
};
