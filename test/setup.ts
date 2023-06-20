/**
 * React Starter Kit (https://www.reactstarterkit.com/)
 *
 * Copyright © 2014-present Kriasoft, LLC. All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE.txt file in the root directory of this source tree.
 */

/* Configure Mocha test runner, see package.json/scripts/test */

import "global-jsdom/register";
import { use } from "chai";
import chaiJSDOM from "chai-jsdom";
import nodeCrypto from "crypto";

use(chaiJSDOM);

process.env.NODE_ENV = "test";

function noop() {
  return null;
}

window.crypto.randomUUID = nodeCrypto.randomUUID;

require.extensions[".css"] = noop;
require.extensions[".scss"] = noop;
require.extensions[".md"] = noop;
require.extensions[".png"] = noop;
require.extensions[".svg"] = noop;
require.extensions[".jpg"] = noop;
require.extensions[".jpeg"] = noop;
require.extensions[".gif"] = noop;
