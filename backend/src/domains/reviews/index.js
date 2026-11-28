'use strict';

const createService = require('./service');
const routes = require('./routes');

// Miền đánh giá: khách đánh giá sản phẩm đã nhận, kèm ảnh thật.
module.exports = function createDanhGia(providers) {
  const service = createService(providers);
  return { service, router: routes({ service, auth: providers.auth }) };
};
