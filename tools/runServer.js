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
import cp from "child_process";
import webpackConfig from "./webpack.config";

// Should match the text string used in `src/server.js/server.listen(...)`
const RUNNING_REGEXP = /The server is running at http:\/\/((.*?):?[0-9]{0,})\//;

let server;
let pending = true;
const [, serverConfig] = webpackConfig;
const serverPath = path.join(
  serverConfig.output.path,
  serverConfig.output.filename.replace("[name]", "server")
);

// Launch or restart the Node.js server
function runServer() {
  return new Promise((resolve) => {
    function onStdOut(data) {
      const time = new Date().toTimeString();
      const match = data.toString("utf8").match(RUNNING_REGEXP);

      process.stdout.write(time.replace(/.*(\d{2}:\d{2}:\d{2}).*/, "[$1] "));
      process.stdout.write(data);

      if (match) {
        server.host = match[1];
        server.hostname = match[2];
        server.stdout.removeListener("data", onStdOut);
        server.stdout.on("data", (x) => process.stdout.write(x));
        pending = false;
        resolve(server);
      }
    }

    if (server) {
      server.kill("SIGTERM");
    }

    server = cp.spawn("bun", [serverPath], {
      env: { NODE_ENV: "development", ...process.env },
      silent: false,
    });

    if (pending) {
      server.once("exit", (code, signal) => {
        if (pending) {
          throw new Error(
            `Server terminated unexpectedly with code: ${code} signal: ${signal}`
          );
        }
      });
    }

    server.stdout.on("data", onStdOut);
    server.stderr.on("data", (x) => process.stderr.write(x));

    return server;
  });
}

process.on("exit", () => {
  if (server) {
    server.kill("SIGTERM");
  }
});

export default runServer;
