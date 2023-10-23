/**
 * React Starter Kit (https://www.reactstarterkit.com/)
 *
 * Copyright © 2014-present Kriasoft, LLC. All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE.txt file in the root directory of this source tree.
 */

/* eslint-disable no-promise-executor-return */

import fs from "fs";
import path from "path";
import express from "express";
import webpack from "webpack";
import webpackDevMiddleware from "webpack-dev-middleware";
import webpackHotMiddleware from "webpack-hot-middleware";
import createLaunchEditorMiddleware from "react-dev-utils/errorOverlayMiddleware";
import https from "https";
import webpackConfig from "./webpack.config";
import run from "./lib/runTask";
import clean from "./clean";
import formatDate from "./lib/formatDate";

// https://webpack.js.org/configuration/watch/#watchoptions
const watchOptions = {
  // Watching may not work with NFS and machines in VirtualBox
  // Uncomment next line if it is your case (use true or interval in milliseconds)
  // poll: true,
  // Decrease CPU or memory usage in some file systems
  // ignored: /node_modules/,
};

function createCompilationPromise(name, compiler, config) {
  return new Promise((resolve, reject) => {
    let timeStart = new Date();
    compiler.hooks.compile.tap(name, () => {
      timeStart = new Date();
      console.info(`[${formatDate(timeStart)}] Compiling '${name}'...`);
    });

    compiler.hooks.done.tap(name, (stats) => {
      console.info(stats.toString(config.stats));
      const timeEnd = new Date();
      const time = timeEnd.getTime() - timeStart.getTime();
      if (stats.hasErrors()) {
        console.info(
          `[${formatDate(
            timeEnd
          )}] Failed to compile '${name}' after ${time} ms`
        );
        reject(new Error("Compilation failed!"));
      } else {
        console.info(
          `[${formatDate(
            timeEnd
          )}] Finished '${name}' compilation after ${time} ms`
        );
        resolve(stats);
      }
    });
  });
}

let server;

/**
 * Launches a development web server with "live reload" functionality -
 * synchronizing URLs, interactions and code changes across multiple devices.
 */
async function start() {
  if (server) return server;
  server = express();
  server.use(createLaunchEditorMiddleware());
  server.use(express.static(path.resolve(__dirname, "../public")));

  // Configure client-side hot module replacement
  const clientConfig = webpackConfig.find((config) => config.name === "client");
  clientConfig.entry.client = ["./tools/lib/webpackHotDevClient"]
    .concat(clientConfig.entry.client)
    .sort((a, b) => b.includes("polyfill") - a.includes("polyfill"));
  clientConfig.output.filename = clientConfig.output.filename.replace(
    "chunkhash",
    "hash"
  );
  clientConfig.output.chunkFilename = clientConfig.output.chunkFilename.replace(
    "chunkhash",
    "hash"
  );
  clientConfig.module.rules = clientConfig.module.rules.filter(
    (x) => x.loader !== "null-loader"
  );
  clientConfig.plugins.push(new webpack.HotModuleReplacementPlugin());

  // Configure server-side hot module replacement
  const serverConfig = webpackConfig.find((config) => config.name === "server");
  serverConfig.output.hotUpdateMainFilename = "updates/[hash].hot-update.json";
  serverConfig.output.hotUpdateChunkFilename =
    "updates/[id].[hash].hot-update.js";
  serverConfig.module.rules = serverConfig.module.rules.filter(
    (x) => x.loader !== "null-loader"
  );
  serverConfig.plugins.push(new webpack.HotModuleReplacementPlugin());

  // Configure compilation
  await run(clean);
  const multiCompiler = webpack(webpackConfig);
  const clientCompiler = multiCompiler.compilers.find(
    (compiler) => compiler.name === "client"
  );
  const serverCompiler = multiCompiler.compilers.find(
    (compiler) => compiler.name === "server"
  );
  const clientPromise = createCompilationPromise(
    "client",
    clientCompiler,
    clientConfig
  );
  const serverPromise = createCompilationPromise(
    "server",
    serverCompiler,
    serverConfig
  );

  // https://github.com/webpack/webpack-dev-middleware
  server.use(
    webpackDevMiddleware(clientCompiler, {
      publicPath: clientConfig.output.publicPath,
    })
  );

  // https://github.com/glenjamin/webpack-hot-middleware
  server.use(webpackHotMiddleware(clientCompiler, { log: false }));

  let appPromise;
  let appPromiseResolve;
  let appPromiseIsResolved = true;
  serverCompiler.hooks.compile.tap("server", () => {
    if (!appPromiseIsResolved) return;
    appPromiseIsResolved = false;
    // eslint-disable-next-line no-return-assign
    appPromise = new Promise((resolve) => (appPromiseResolve = resolve));
  });

  let app;
  server.use((req, res) => {
    appPromise
      .then(() => app.handle(req, res))
      .catch((error) => console.error(error));
  });

  serverCompiler.watch(watchOptions, (error, stats) => {
    if (app && !error && !stats.hasErrors()) {
      appPromiseIsResolved = true;
      appPromiseResolve();
    }
  });

  // Wait until both client-side and server-side bundles are ready
  await clientPromise;
  await serverPromise;

  const timeStart = new Date();
  console.info(`[${formatDate(timeStart)}] Launching server...`);

  // Load compiled src/server.js as a middleware
  // eslint-disable-next-line global-require, import/no-unresolved, import/extensions, @typescript-eslint/no-var-requires
  const build = require("../build/server");
  app = build.default;
  appPromiseIsResolved = true;
  appPromiseResolve();

  https
    .createServer(
      {
        key: fs.readFileSync(
          path.join(__dirname, "../cert/server.key"),
          "utf-8"
        ),
        cert: fs.readFileSync(
          path.join(__dirname, "../cert/server.crt"),
          "utf-8"
        ),
      },
      server
    )
    .listen(process.env.PORT || 3000);

  const timeEnd = new Date();
  const time = timeEnd.getTime() - timeStart.getTime();
  console.info(`[${formatDate(timeEnd)}] Server launched after ${time} ms`);

  return server;
}

export default start;
