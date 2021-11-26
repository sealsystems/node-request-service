'use strict';

const log = require('@sealsystems/log').getLogger();

const resolve = async function (consul, service) {
  if (!consul) {
    throw new Error('Consul is missing.');
  }
  if (!service) {
    throw new Error('Service name is missing.');
  }

  let hosts;

  try {
    hosts = await consul.resolveService(service);
  } catch (ex) {
    log.error('Error resolving requested service.', {
      service,
      err: ex
    });

    throw ex;
  }

  return hosts;
};

module.exports = resolve;
