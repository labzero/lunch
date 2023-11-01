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
import "../env";

let server: Application;

// Launch or restart the Node.js server
async function runServer() {
  if (!server) {
    server = (await import("../src/server.tsx")).default;
  }
}

export default runServer;
