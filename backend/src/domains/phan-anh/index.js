'use strict';

const createService = require('./service');
const routes = require('./routes');

// Miền phản ánh: khách báo hàng giả/sai mô tả (gắn với lô nếu có mã), nhân sự xử lý.
module.exports = function createPhanAnh(providers) {
  const service = createService(providers);
  const { khach, admin } = routes({ service, auth: providers.auth });
  return { service, khachRouter: khach, adminRouter: admin };
};
