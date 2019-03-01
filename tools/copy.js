/**
 * React Starter Kit (https://www.reactstarterkit.com/)
 *
 * Copyright © 2014-present Kriasoft, LLC. All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE.txt file in the root directory of this source tree.
 */

import path from 'path';
import chokidar from 'chokidar';
import {
  writeFile, copyFile, makeDir, copyDir, cleanDir
} from './lib/fs';
import pkg from '../package.json';
import { format } from './run';

/**
 * Copies static files such as robots.txt, favicon.ico to the
 * output (build) folder.
 */
async function copy() {
  await makeDir('build');
  await Promise.all([
    writeFile(
      'build/package.json',
      JSON.stringify(
        {
          private: true,
          engines: pkg.engines,
          dependencies: pkg.dependencies,
          scripts: {
            start: 'node server.js',
          },
        },
        null,
        2,
      ),
    ),
    copyFile('LICENSE.txt', 'build/LICENSE.txt'),
    copyFile('yarn.lock', 'build/yarn.lock'),
    copyDir('public', 'build/public'),
    copyFile('database.js', 'build/database.js'),
    copyFile('.sequelizerc', 'build/.sequelizerc'),
    copyDir('db', 'build/db'),
    copyDir('cert', 'build/cert'),
    makeDir('build/src').then(() => makeDir('build/src/models')).then(() => copyFile('src/models/db.js', 'build/src/models/db.js'))
  ]);

  if (process.argv.includes('--release')) {
    await copyFile('.env.prod', 'build/.env');
  } else {
    await copyFile('.env', 'build/.env');
    if (process.env.NODE_ENV === 'test') {
      await copyFile('.env.test', 'build/.env.test');
    }
  }

  if (process.argv.includes('--watch')) {
    const watcher = chokidar.watch(['public/**/*'], { ignoreInitial: true });

    watcher.on('all', async (event, filePath) => {
      const start = new Date();
      const src = path.relative('./', filePath);
      const dist = path.join(
        'build/',
        src.startsWith('src') ? path.relative('src', src) : src,
      );
      switch (event) {
        case 'add':
        case 'change':
          await makeDir(path.dirname(dist));
          await copyFile(filePath, dist);
          break;
        case 'unlink':
        case 'unlinkDir':
          cleanDir(dist, { nosort: true, dot: true });
          break;
        default:
          return;
      }
      const end = new Date();
      const time = end.getTime() - start.getTime();
      console.info(`[${format(end)}] ${event} '${dist}' after ${time} ms`);
    });
  }
}

export default copy;
