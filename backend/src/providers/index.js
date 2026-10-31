'use strict';

// Tập hợp mọi Provider: cửa DUY NHẤT để các mối quan tâm xuyên suốt (CSDL, xác thực,
// mật khẩu, số ngẫu nhiên, log, HTTP) đi vào các miền nghiệp vụ.
const { createDb } = require('./db');
const { createAuth } = require('./auth');
const { createHttp } = require('./http');
const { password } = require('./password');
const { random } = require('./random');
const { logger } = require('./logger');

function createProviders({ pool, config }) {
  const db = createDb(pool);
  return {
    config,
    db,
    auth: createAuth({ db, config }),
    http: createHttp({ logger }),
    password,
    random,
    logger,
  };
}

module.exports = { createProviders };
