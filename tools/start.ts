/**
 * React Starter Kit (https://www.reactstarterkit.com/)
 *
 * Copyright © 2014-present Kriasoft, LLC. All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE.txt file in the root directory of this source tree.
 */

/* eslint-disable no-promise-executor-return */

import { Application } from "express";
import webpack, {
  Compiler,
  Configuration,
  EntryObject,
  ModuleOptions,
  RuleSetRule,
} from "webpack";
import webpackConfig, { clientConfig } from "./webpack.config";
import run from "./lib/runTask";
import clean from "./clean";
import formatDate from "./lib/formatDate";

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

declare global {
  var server: Application;
}

/**
 * Launches a development web server with "live reload" functionality -
 * synchronizing URLs, interactions and code changes across multiple devices.
 */
async function start() {
  if (!globalThis.server) {
    // Configure client-side hot module replacement
    const clientEntry = clientConfig.entry as EntryObject;
    (clientEntry.client as string[]) = ["./tools/lib/webpackHotDevClient"]
      .concat(clientEntry.client as string[])
      .sort(
        (a, b) =>
          Number(b.includes("polyfill")) - Number(a.includes("polyfill"))
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

    // Configure compilation
    await run(clean);
    const multiCompiler = webpack(webpackConfig);
    const clientCompiler = multiCompiler.compilers.find(
      (compiler) => compiler.name === "client"
    )!;
    const clientPromise = createCompilationPromise(
      "client",
      clientCompiler,
      clientConfig
    );
    clientCompiler.run();

    // Wait until both client-side and server-side bundles are ready
    await clientPromise;
  }

  const timeStart = new Date();
  console.info(`[${formatDate(timeStart)}] Launching server...`);

  globalThis.server = (await import("../src/server.tsx")).default;

  const timeEnd = new Date();
  const time = timeEnd.getTime() - timeStart.getTime();
  console.info(`[${formatDate(timeEnd)}] Server launched after ${time} ms`);

  return globalThis.server;
}

export default start;
