'use strict';

const createService = require('./service');
const routes = require('./routes');

// Miền đơn hàng: giỏ hàng, đặt đơn (gán lô FIFO, trừ tồn trong một transaction),
// xem đơn và chuyển trạng thái theo vai trò.
module.exports = function createDonHang(providers) {
  const service = createService(providers);
  const { gio, don, admin } = routes({ service, auth: providers.auth });
  return { service, gioRouter: gio, donRouter: don, adminRouter: admin };
};
