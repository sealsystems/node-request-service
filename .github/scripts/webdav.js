/* eslint-disable no-empty */
'use strict';

const fs = require('fs');
const path = require('path');

const needle = require('needle');
const getenv = require('getenv');
const { createClient } = require('webdav');

const [username, password] = getenv('DELIVERY_CREDENTIALS').split(':');
const deliveryUrl = getenv('DELIVERY_URL', 'https://ftpx.sealsystems.de/webdav');
// const deliveryUrl = getenv('DELIVERY_URL', 'https://delivery.sealsystems.de/remote.php/webdav');
const [, , command, source, target] = process.argv;

const logAndTerminate = function (err, promise) {
  if (promise) {
    console.error('Unhandled rejection occurred. Terminate process.', { err, promise });
  } else {
    console.error('Uncaught exception occurred. Terminate process.', { err });
  }
  // eslint-disable-next-line no-process-exit
  process.exit(1);
};
process.on('uncaughtException', logAndTerminate);
process.on('unhandledRejection', logAndTerminate);

const client = createClient(deliveryUrl, {
  username,
  password
});

const sleep = async function (milliseconds) {
  return new Promise((resolve) => {
    setTimeout(resolve, milliseconds);
  });
};

const mkdirp = async function (fullPath) {
  let root = '';
  for (const dir of fullPath.split('/')) {
    if (dir === '') {
      continue;
    }

    root = `${root}/${dir}`;
    if (!(await client.exists(root))) {
      await client.createDirectory(root);

      while (!client.exists(root)) {
        console.log(`Waiting until "${root}" has been created.`);
        await sleep(1000);
      }
    }
  }
};

const copy = async function () {
  // Ensure that target dir exist, errors will be caught while copying
  let loop = 0;
  let finished = false;
  let lastErr;
  while (!finished && loop < 10) {
    try {
      await mkdirp(path.dirname(target));
    } catch (e) {
      console.error('Error while creating directory:', e.message);
    }
    try {
      await client.copyFile(source, target);
      finished = true;
    } catch (e) {
      lastErr = e;
      console.error('Error while copying file:', e.message);
      await new Promise((resolve) => {
        setTimeout(resolve, 2000);
      });
    }
    loop++;
  }
  if (!finished) {
    throw lastErr;
  }
};

const exists = async function () {
  let loop = 0;
  let finished = false;
  let result = false;
  while (!finished && loop < 10) {
    try {
      result = await client.exists(source);
      finished = true;
    } catch (e) {
      console.error('Error while checking file:', e.message);
      await new Promise((resolve) => {
        setTimeout(resolve, 2000);
      });
    }
    loop++;
  }

  if (!result) {
    console.log(`${source} not found.`);
    // eslint-disable-next-line no-process-exit
    process.exit(1);
  }
  console.log(`${source} found.`);
};

const ls = async function () {
  // Split source to allow globbing
  let mySource = source;
  let options;
  if (mySource.includes('*')) {
    options = { glob: mySource.replace(/^.*\//g, '') };
    mySource = mySource.replace(/\/[^/]*$/, '');
  }

  let result;
  let loop = 0;
  let finished = false;
  let lastErr;
  while (!finished && loop < 10) {
    try {
      result = await client.getDirectoryContents(mySource, options);
      finished = true;
    } catch (err) {
      lastErr = err;
      if (err.response && err.response.status === 404) {
        console.error(`Error: Path "${mySource}" not found.`);
        // eslint-disable-next-line no-process-exit
        process.exit(1);
      }
      console.error('Error while listing files:', err.message);
      await new Promise((resolve) => {
        setTimeout(resolve, 2000);
      });
    }
    loop++;
  }
  if (!finished) {
    throw lastErr;
  }

  console.log(result.map((item) => item.basename).join('\n'));
};

const mkdir = async function () {
  let loop = 0;
  let finished = false;
  while (!finished && loop < 10) {
    try {
      await mkdirp(source);
      finished = true;
    } catch (e) {
      console.error('Error while creating directory:', e.message);
    }
    loop++;
  }
};

const move = async function () {
  // Ensure that target dir exist, errors will be caught while moving
  try {
    await mkdirp(path.dirname(target));
  } catch (e) {
    console.error('Error while creating directory:', e.message);
  }
  await client.moveFile(source, target);
};

const pull = async function () {
  let loop = 0;
  let finished = false;
  let lastErr;
  let result;
  while (!finished && loop < 10) {
    try {
      result = await new Promise((resolve, reject) => {
        const writeStream = fs.createWriteStream(target);
        const readStream = client.createReadStream(source);
        const error = (err) => {
          readStream.removeListener('error', error);
          writeStream.removeListener('error', error);
          // eslint-disable-next-line no-use-before-define
          writeStream.removeListener('close', done);
          reject(err);
        };

        const done = (err) => {
          if (err) {
            return error(err);
          }
          readStream.removeListener('error', error);
          writeStream.removeListener('error', error);
          writeStream.removeListener('close', done);
          resolve();
        };

        readStream.once('error', error);
        writeStream.once('error', error);
        writeStream.once('close', done);

        readStream.pipe(writeStream);
      });
      finished = true;
    } catch (err) {
      console.error('Error while pulling files', err.message);
      await new Promise((resolve) => {
        setTimeout(resolve, 2000);
      });
    }
    loop++;
  }
  if (!finished) {
    throw lastErr;
  }
  return result;
};

const push = async function () {
  let loop = 0;
  let finished = false;
  let response;
  while (!finished && loop < 10) {
    try {
      // Ensure that target dir exist, errors will be caught while pushing
      try {
        await mkdirp(path.dirname(target));
      } catch (e) {
        console.error('Error while creating directory:', e.message);
      }
      // Use needle instead of webdav module for streaming
      response = await needle(
        'put',
        `${deliveryUrl}${encodeURI(target)}`,
        fs.createReadStream(source),
        {
          username,
          password,
          content_type: 'application/octet-stream',
          // eslint-disable-next-line no-sync
          stream_length: fs.statSync(source).size,
          follow: 10 // allow up to 10 redirections
        }
      );
      if (response.statusCode < 300) {
        finished = true;
      }
    } catch (err) {
      console.error('Error while pushing file', err.message);
      await new Promise((resolve) => {
        setTimeout(resolve, 2000);
      });
    }
    if (response && response.statusCode >= 400 && response.statusCode < 500) {
      throw new Error(`Unexprected status code ${response.statusCode} received while pushing to "${target}".`);
    }
    loop++;
  }
};

const rm = async function () {
  await client.deleteFile(source);
};

(async () => {
  switch (command) {
    case 'copy':
    case 'cp':
      await copy();
      break;
    case 'exists':
      await exists();
      break;
    case 'ls':
      await ls();
      break;
    case 'mkdir':
      await mkdir();
      break;
    case 'move':
    case 'mv':
      await move();
      break;
    case 'push':
      await push();
      break;
    case 'pull':
      await pull();
      break;
    case 'remove':
    case 'rm':
      await rm();
      break;
    default:
      throw new Error(`Invalid command: ${command}`);
  }
})();
