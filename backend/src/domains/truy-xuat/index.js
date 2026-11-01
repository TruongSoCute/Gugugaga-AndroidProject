'use strict';

const createService = require('./service');
const routes = require('./routes');

// Miền truy xuất: lô sản xuất, bước truy xuất và API quét QR công khai.
// deps: { nhaCungCap } — service miền khác, do app wiring truyền vào.
module.exports = function createTruyXuat(providers, deps) {
  const service = createService(providers, deps);
  const { lo, congKhai } = routes({
    service, auth: providers.auth, http: providers.http, config: providers.config,
  });
  return { service, loRouter: lo, publicRouter: congKhai };
};
