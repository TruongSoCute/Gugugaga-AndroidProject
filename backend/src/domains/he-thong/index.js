'use strict';

const createService = require('./service');
const routes = require('./routes');

module.exports = function createHeThong(providers) {
  const service = createService(providers);
  return { service, healthRouter: routes({ service }) };
};
