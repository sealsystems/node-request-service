# @sealsystems/request-service


Makes a request to a service, using consul for discovery and lookup.

## Installation

```shell
$ npm install @sealsystems/request-service
```

## Quick start

First you need to add a reference to @sealsystems/request-service within your application.

```javascript
const requestService = require('@sealsystems/request-service');
```

**Please note:** A connection to consul must already exist before you can use the module.

To create a HTTP/HTTPS request to an instance of a service use:

```javascript
const consul = require('@sealsystems/consul');
consul.connect(...);

const req = await requestService({ consul, service: 'myService' });

req.on('connect', () => {
  console.log('Connected to service!');
});

req.write('Hello service!');
req.end();
```

The first parameter is an `options` object that can contain the following properties:

| property     | type            | description                                                                            |
|--------------|-----------------|----------------------------------------------------------------------------------------|
| consul       | required object | Consul client for service discovery                                                    |
| service      | required string | Name of the service to access                                                          |
| headers      | optional object | Additional HTTP/HTTPS headers                                                          |
| method       | optional string | HTTP/HTTPS method, default `POST`                                                      |
| path         | optional string | URL-path to access, default `/`                                                        |
| responseType | optional string | Valid value: `json`, read JSON response and return as object                           |
| json         | optional object | Only valid together with responseType. Send object given in `json` property to service |

Here is an example of a more complete `options` object:

```javascript
const options = {
  consul,
  headers: {
    'content-type': 'application/json'
  },
  method: 'POST',
  path: '/job',
  service: 'myService'
};
```

The return value `req` contains a [http.ClientRequest](https://nodejs.org/api/http.html#http_class_http_clientrequest) object for further use.

## HTTP and HTTPS

The protocol used for a connection depends on the target (the service resides in the local or a remote host) and the value of the environment variable TLS_UNPROTECTED. The TLS certificates provided by `@sealsystems/tlscert` will be used for HTTPS connections. It is not possible to override the chosen protocol.

Used protocol:

| TLS_UNPROTECTED | local service | remote service |
| --------------- | ------------- | -------------- |
| 'world'         | HTTP          | HTTP           |
| 'loopback'      | HTTP          | HTTPS          |
| 'none'          | HTTPS         | HTTPS          |
