/**
 * React Starter Kit (https://www.reactstarterkit.com/)
 *
 * Copyright © 2014-present Kriasoft, LLC. All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE.txt file in the root directory of this source tree.
 */

import UniversalRouter, { Route } from "universal-router";
import { AppContext, AppRoute } from "./interfaces";

export default (routes: Route<AppContext, AppRoute>) =>
  new UniversalRouter<AppContext, AppRoute>(routes, {
    async resolveRoute(context, params): Promise<AppRoute | void> {
      if (typeof context.route.action === "function") {
        const route = await context.route.action(context, params);
        return route;
      }
      return undefined;
    },
  });
