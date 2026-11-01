'use strict';

const createService = require('./service');
const routes = require('./routes');

module.exports = function createNhaCungCap(providers) {
  const service = createService(providers);
  const { pub, admin } = routes({ service, auth: providers.auth });
  return { service, publicRouter: pub, adminRouter: admin };
};
