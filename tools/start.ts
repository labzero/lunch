/**
 * React Starter Kit (https://www.reactstarterkit.com/)
 *
 * Copyright © 2014-present Kriasoft, LLC. All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE.txt file in the root directory of this source tree.
 */

/* eslint-disable no-promise-executor-return */

import path from "path";
import express, { Application } from "express";
import webpack, {
  Compiler,
  Configuration,
  EntryObject,
  ModuleOptions,
  RuleSetRule,
} from "webpack";
import webpackDevMiddleware from "webpack-dev-middleware";
import webpackHotMiddleware from "webpack-hot-middleware";
import createLaunchEditorMiddleware from "react-dev-utils/errorOverlayMiddleware";
import webpackConfig, { clientConfig, serverConfig } from "./webpack.config";
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

function createCompilationPromise(
  name: string,
  compiler: Compiler,
  config: Configuration
) {
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

let server: Application;

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
  const clientEntry = clientConfig.entry as EntryObject;
  (clientEntry.client as string[]) = ["./tools/lib/webpackHotDevClient"]
    .concat(clientEntry.client as string[])
    .sort(
      (a, b) => Number(b.includes("polyfill")) - Number(a.includes("polyfill"))
    );

  const clientOutput = clientConfig.output!;

  clientOutput.filename = (clientOutput.filename as string).replace(
    "chunkhash",
    "hash"
  );
  clientOutput.chunkFilename = (clientOutput.chunkFilename as string).replace(
    "chunkhash",
    "hash"
  );

  const clientModule = clientConfig.module as ModuleOptions;
  clientModule.rules = (clientModule.rules as RuleSetRule[]).filter(
    (x) => x.loader !== "null-loader"
  );
  clientConfig.plugins!.push(new webpack.HotModuleReplacementPlugin());

  // Configure server-side hot module replacement
  const serverOutput = serverConfig.output!;
  serverOutput.hotUpdateMainFilename = "updates/[hash].hot-update.json";
  serverOutput.hotUpdateChunkFilename = "updates/[id].[hash].hot-update.js";

  const serverModule = serverConfig.module as ModuleOptions;
  serverModule.rules = (serverModule.rules as RuleSetRule[]).filter(
    (x) => x.loader !== "null-loader"
  );
  serverConfig.plugins!.push(new webpack.HotModuleReplacementPlugin());

  // Configure compilation
  await run(clean);
  const multiCompiler = webpack(webpackConfig);
  const clientCompiler = multiCompiler.compilers.find(
    (compiler) => compiler.name === "client"
  )!;
  const serverCompiler = multiCompiler.compilers.find(
    (compiler) => compiler.name === "server"
  )!;
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
      publicPath: clientOutput.publicPath,
    })
  );

  // https://github.com/glenjamin/webpack-hot-middleware
  server.use(webpackHotMiddleware(clientCompiler, { log: false }));

  let appPromise: Promise<void>;
  let appPromiseResolve: () => void;
  let appPromiseIsResolved = true;
  serverCompiler.hooks.compile.tap("server", () => {
    if (!appPromiseIsResolved) return;
    appPromiseIsResolved = false;
    // eslint-disable-next-line no-return-assign
    appPromise = new Promise((resolve) => (appPromiseResolve = resolve));
  });

  let app: Application | undefined;
  server.use((req, res) => {
    appPromise
      // @ts-expect-error app.handle is an internal function
      .then(() => app!.handle(req, res))
      .catch((error) => console.error(error));
  });

  serverCompiler.watch(watchOptions, (error, stats) => {
    if (app && !error && !stats!.hasErrors()) {
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
  appPromiseResolve!();

  const timeEnd = new Date();
  const time = timeEnd.getTime() - timeStart.getTime();
  console.info(`[${formatDate(timeEnd)}] Server launched after ${time} ms`);

  return server;
}

export default start;
