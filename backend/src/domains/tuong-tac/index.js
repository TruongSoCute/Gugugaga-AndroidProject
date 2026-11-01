'use strict';

const createService = require('./service');
const routes = require('./routes');

// Miền tương tác của khách: yêu thích sản phẩm, theo dõi nhà cung cấp.
module.exports = function createTuongTac(providers) {
  const service = createService(providers);
  const { yeuThich, theoDoi } = routes({ service, auth: providers.auth });
  return { service, yeuThichRouter: yeuThich, theoDoiRouter: theoDoi };
};
