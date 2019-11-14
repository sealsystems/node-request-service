'use strict';

const getenv = require('getenv');
const log = require('@sealsystems/log').getLogger();
const retry = require('retry');

const connectService = require('@sealsystems/connect-service');

const resolve = require('./resolve');

const requestServiceConsul = async function(options) {
  if (!options) {
    throw new Error('Options are missing.');
  }
  if (!options.consul) {
    throw new Error('Consul is missing.');
  }
  if (!options.service) {
    throw new Error('Service name is missing.');
  }

  const { service } = options;

  const hosts = await resolve(options.consul, service);

  if (!hosts.length) {
    log.error('No available instances for service found.', { service });

    throw new Error('No service instances available.');
  }

  const operation = retry.operation({
    retries: hosts.length - 1,
    minTimeout: 0,
    maxTimeout: 0
  });

  let index = 0;

  const client = await new Promise((resolvePromise, reject) => {
    operation.attempt(async () => {
      const host = hosts[index++];

      let serviceClient;

      try {
        serviceClient = await connectService(options, host);
      } catch (ex) {
        if (operation.retry(ex)) {
          return;
        }

        return reject(operation.mainError());
      }

      resolvePromise(serviceClient);
    });
  });

  return client;
};

const requestService = async function(options) {
  if (!options) {
    throw new Error('Options are missing.');
  }
  if (!options.service) {
    throw new Error('Service name is missing.');
  }

  const serviceDiscovery = getenv('SERVICE_DISCOVERY', 'consul');
  const servicePort = getenv.int('SERVICE_DISCOVERY_PORT', 3000);

  if (serviceDiscovery === 'consul') {
    return await requestServiceConsul(options);
  }

  options.port = servicePort;
  options.hostname = options.service;

  return await connectService(options, { name: options.service, port: servicePort });
};

module.exports = requestService;
