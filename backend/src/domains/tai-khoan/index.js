'use strict';

const createService = require('./service');
const routes = require('./routes');

module.exports = function createTaiKhoan(providers) {
  const service = createService(providers);
  return { service, authRouter: routes({ service, auth: providers.auth }) };
};
