/**
 * React Starter Kit (https://www.reactstarterkit.com/)
 *
 * Copyright © 2014-present Kriasoft, LLC. All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE.txt file in the root directory of this source tree.
 */

import { RouteContext } from "universal-router";
import { AppContext, AppRoute } from "../../interfaces";
import render404 from "../helpers/render404";

export default (context: RouteContext<AppRoute, AppContext>) =>
  render404(context);
