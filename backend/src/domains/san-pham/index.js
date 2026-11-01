'use strict';

const createService = require('./service');
const routes = require('./routes');

// deps: { nhaCungCap } — service của miền khác, do app wiring truyền vào.
module.exports = function createSanPham(providers, deps) {
  const service = createService(providers, deps);
  const { pub, admin, cuaToi } = routes({ service, auth: providers.auth });
  return { service, publicRouter: pub, adminRouter: admin, cuaToiRouter: cuaToi };
};
