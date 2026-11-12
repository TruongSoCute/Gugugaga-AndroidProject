'use strict';

const createService = require('./service');
const routes = require('./routes');

module.exports = function createTaiKhoan(providers) {
  const service = createService(providers);

  const {
    authRouter,
    adminRouter,
  } = routes({
    service,
    auth: providers.auth,
  });

  return {
    service,
    authRouter,
    adminRouter,
  };
};