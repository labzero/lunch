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
import path from "path";
import { serverConfig } from "./webpack.config";
import "../env";

let server: Application;
const serverPath = path.join(
  serverConfig.output!.path!,
  (serverConfig.output!.filename as string).replace("[name]", "server")
);

// Launch or restart the Node.js server
async function runServer() {
  // eslint-disable-next-line
  server = require(serverPath).default;

  return server;
}

export default runServer;
