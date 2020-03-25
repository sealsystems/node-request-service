'use strict';

const assert = require('assertthat');
const nodeenv = require('nodeenv');
const proxyquire = require('proxyquire');

let connectError;
let connectedServices;
let resolveError;
let resolvedServices;
let path;

const requestService = proxyquire('../lib/requestService', {
  async '@sealsystems/connect-service'(options, host) {
    assert.that(options.consul).is.not.falsy();
    path = options.path;

    if (connectError) {
      throw connectError;
    }

    connectedServices.push(host);

    return `This is a client.`;
  },
  async './resolve'() {
    if (resolveError) {
      throw resolveError;
    }

    return resolvedServices;
  }
});

suite('requestService', () => {
  setup(async () => {
    connectError = null;
    connectedServices = [];
    resolveError = null;
    resolvedServices = [];
    path = null;
  });

  test('is a function', async () => {
    assert.that(requestService).is.ofType('function');
  });

  test('throws an error if options is missing.', async () => {
    await assert
      .that(async () => {
        await requestService();
      })
      .is.throwingAsync('Options are missing.');
  });

  test('throws an error if consul is missing.', async () => {
    await assert
      .that(async () => {
        await requestService({ service: 'foo' });
      })
      .is.throwingAsync('Consul is missing.');
  });

  test('throws an error if service name is missing.', async () => {
    await assert
      .that(async () => {
        await requestService({ consul: {} });
      })
      .is.throwingAsync('Service name is missing.');
  });

  test('throws an error if resolve failed.', async () => {
    resolveError = new Error('Best Error Ever');

    await assert
      .that(async () => {
        await requestService({
          consul: {},
          service: 'test service',
          path: '/test/path'
        });
      })
      .is.throwingAsync('Best Error Ever');
  });

  test('throws an error if empty list of services is given.', async () => {
    await assert
      .that(async () => {
        await requestService({
          consul: {},
          service: 'test service',
          path: '/test/path'
        });
      })
      .is.throwingAsync('No service instances available.');
  });

  test('throws an error if connecting each given service failed.', async () => {
    resolvedServices = ['service1', 'service2'];

    connectError = new Error('foo');

    await assert
      .that(async () => {
        await requestService({
          consul: {},
          service: 'test service',
          path: '/test/path'
        });
      })
      .is.throwingAsync('foo');
  });

  test('returns connected client on success.', async () => {
    resolvedServices = ['service1', 'service2'];

    const client = await requestService({
      consul: {},
      service: 'test service',
      path: '/test/path'
    });

    assert.that(connectedServices.length).is.equalTo(1);
    assert.that(connectedServices[0]).is.equalTo(resolvedServices[0]);
    assert.that(client).is.equalTo('This is a client.');
    assert.that(path).is.equalTo('/test/path');
  });

  suite('cloud service discovery', () => {
    test('directly uses http.request.', async () => {
      const restore = nodeenv('SERVICE_DISCOVERY', 'cloud');
      const service = 'bodyscanner';
      const client = await requestService({
        consul: {},
        service,
        path: '/test/path'
      });

      assert.that(connectedServices.length).is.equalTo(1);
      assert.that(connectedServices[0]).is.equalTo({ name: service, port: 3000 });
      assert.that(client).is.equalTo('This is a client.');
      restore();
    });
  });

  test('returns connected client on success with special charaters in the path.', async () => {
    resolvedServices = ['service1', 'service2'];

    const client = await requestService({
      consul: {},
      service: 'test service',
      path: '/v3/printers/j*ü?=) (/&% $§:ÖÄ öäß+~e'
    });

    assert.that(connectedServices.length).is.equalTo(1);
    assert.that(connectedServices[0]).is.equalTo(resolvedServices[0]);
    assert.that(client).is.equalTo('This is a client.');

    assert
      .that(path)
      .is.equalTo('/v3/printers/j*%C3%BC%3F%3D)%20(/%26%25%20%24%C2%A7%3A%C3%96%C3%84%20%C3%B6%C3%A4%C3%9F%2B~e');
  });
});
