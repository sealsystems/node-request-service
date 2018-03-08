# @sealsystems/request-service

[![CircleCI](https://circleci.com/gh/sealsystems/seal-request-service.svg?style=svg)](https://circleci.com/gh/sealsystems/seal-request-service)
[![AppVeyor](https://ci.appveyor.com/api/projects/status/oi6bpwnv5emfu2e5?svg=true)](https://ci.appveyor.com/project/Plossys/seal-request-service)

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
const req = await requestService({ service: 'myService' });

req.on('connect', () => {
  console.log('Connected to service!');
});

req.write('Hello service!');
req.end();
```

The first parameter is an `options` object that can contain the following properties:

| property  | type            | description                        |
|-----------|-----------------|------------------------------------|
| service   | required string | Name of the service to access      |
| headers   | optional object | Additional HTTP/HTTPS headers      |
| method    | optional string | HTTP/HTTPS method, default `POST`  |
| path      | optional string | URL-path to access, default `/`    |

Here is an example of a more complete `options` object:

```javascript
const options = {
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

The protocol used for a connection depends on the target (the service resides in the local or a remote host) and the value of the environment variable TLS_UNPROTECTED. The TLS certificates provided by `seal-tlscert` will be used for HTTPS connections. It is not possible to override the chosen protocol.

Used protocol:

| TLS_UNPROTECTED | local service | remote service |
| --------------- | ------------- | -------------- |
| 'world'         | HTTP          | HTTP           |
| 'loopback'      | HTTP          | HTTPS          |
| 'none'          | HTTPS         | HTTPS          |

## Running the build

To build this module use [roboter](https://www.npmjs.com/package/roboter).

```shell
$ bot
```
