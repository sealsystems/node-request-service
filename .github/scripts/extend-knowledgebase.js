'use strict';

const https = require('https');
const fs = require('fs');
const path = require('path');

const needle = require('needle');
const getenv = require('getenv');

const errors = require('../../lib/errors');
const pkg = JSON.parse(fs.readFileSync(path.join(__dirname, '../../package.json')));

const page = {
  type: 'page',
  title: '',
  ancestors: [
    {
      id: 41583585
    }
  ],
  space: {
    key: 'KB'
  },
  body: {
    storage: {
      value: '',
      representation: 'storage'
    }
  }
};

const postInConfluence = async function(page, options) {
  const response = await needle(
    'post',
    'https://sealspace.sealsystems.de/rest/api/content/',
    page,
    options
  );
  console.log('Statuscode: ', response.statusCode);
  console.log('Message: ', response.body.message);
};

let options;
let newPageJson;

for (const error in errors) {
  page.title = `${error}-${pkg.name.replace(/^seal-/, '')}`;
  page.body.storage.value = `<p>${errors[error].message}</p>`
  newPageJson = JSON.stringify(page);
  options = {
    headers: {
      'Authorization': 'Basic ' + Buffer.from(getenv('KB_CREDENTIALS')).toString('base64'),
      'Content-Type': 'application/json',
      'Content-Length': newPageJson.length
    }
  };
  postInConfluence(newPageJson, options)
}