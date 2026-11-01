'use strict';

// Tập hợp mọi Provider: cửa DUY NHẤT để các mối quan tâm xuyên suốt (CSDL, xác thực,
// mật khẩu, số ngẫu nhiên, log, HTTP) đi vào các miền nghiệp vụ.
const { createDb } = require('./db');
const { createAuth } = require('./auth');
const { createHttp } = require('./http');
const { password } = require('./password');
const { random } = require('./random');
const { logger } = require('./logger');
const { createStorage } = require('./storage');

// storage: truyền vào khi kiểm thử (giả lập Supabase Storage); mặc định dùng Supabase thật theo config.
function createProviders({ pool, config, storage }) {
  const db = createDb(pool);
  return {
    config,
    db,
    auth: createAuth({ db, config }),
    http: createHttp({ logger }),
    storage: storage || createStorage({ config }),
    password,
    random,
    logger,
  };
}

module.exports = { createProviders };
