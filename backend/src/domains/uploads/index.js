'use strict';

const createService = require('./service');
const routes = require('./routes');

// Miền tải lên: ảnh đánh giá, ảnh sản phẩm, ảnh cơ sở, ảnh lô -> Supabase Storage.
module.exports = function createTaiLen(providers) {
  const service = createService(providers);
  return { service, router: routes({ service, auth: providers.auth }) };
};
