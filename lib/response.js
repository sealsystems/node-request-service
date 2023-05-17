'use strict';

const log = require('@sealsystems/log').getLogger();

const response = async function (options, client) {
  if (!options.responseType) {
    return client;
  }
  if (options.responseType !== 'json') {
    throw new Error('Unknown response type');
  }

  // eslint-disable-next-line no-async-promise-executor
  return await new Promise((resolve, reject) => {
    const handleError = (err) => {
      log.error('Received error from service', { err, service: options.service });
      return reject(err);
    };

    client.once('error', handleError);

    client.once('response', (clientRes) => {
      log.debug('Service returned status code', { service: options.service, statusCode: clientRes.statusCode });
      client.removeListener('error', handleError);

      if (clientRes.statusCode === 201) {
        log.debug('No data respnse from service', { service: options.service, statusCode: clientRes.statusCode });
        clientRes.destroy();
        return resolve(null);
      }
      if (clientRes.statusCode < 200 || clientRes.statusCode >= 300) {
        log.error('Received error response from service', {
          service: options.service,
          statusCode: clientRes.statusCode
        });
        clientRes.destroy();
        return reject(new Error('Conversion error, set job to error.'));
      }

      const chunks = [];
      let endHandler;
      const dataHandler = (chunk) => {
        chunks.push(chunk);
      };
      const responseHandleError = (err) => {
        log.error('Received error in response from service', { err, service: options.service });
        clientRes.removeListener('data', dataHandler);
        clientRes.removeListener('end', endHandler);
        return reject(err);
      };
      endHandler = () => {
        clientRes.removeListener('data', dataHandler);
        clientRes.removeListener('error', responseHandleError);
        try {
          resolve(JSON.parse(Buffer.concat(chunks).toString('UTF-8')));
        } catch (err) {
          reject(err);
        }
      };

      clientRes.once('error', responseHandleError);
      clientRes.on('data', dataHandler);
      clientRes.once('end', endHandler);
    });

    if (options.json) {
      client.write(JSON.stringify(options.json));
    }
    client.end();
  });
};

module.exports = response;
