'use strict';

const createService = require('./service');
const routes = require('./routes');

// Miền báo cáo: doanh số cho màn hình biểu đồ của app Admin.
module.exports = function createBaoCao(providers) {
  const service = createService(providers);
  return { service, router: routes({ service, auth: providers.auth }) };
};
