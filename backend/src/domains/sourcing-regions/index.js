'use strict';

const createService = require('./service');
const routes = require('./routes');

module.exports = function createDanhMuc(providers) {
  const service = createService(providers);
  return { service, vungRouter: routes({ service }) };
};
