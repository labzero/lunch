/**
 * React Starter Kit (https://www.reactstarterkit.com/)
 *
 * Copyright © 2014-present Kriasoft, LLC. All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE.txt file in the root directory of this source tree.
 */

import UniversalRouter, { Route } from "universal-router";
import { AppContext, AppRoute, FetchWithCache } from "./interfaces";

export default (
  routes: Route<AppRoute, AppContext>,
  fetchWithCache: FetchWithCache
) =>
  new UniversalRouter<AppRoute, AppContext>(routes, {
    async resolveRoute(context, params): Promise<AppRoute | null | undefined> {
      if (typeof context.route.action === "function") {
        const route = await context.route.action(context, params);
        if (route && route.queries && route.payload == null) {
          const cache = {};
          await Promise.all(
            route.queries.map((url) => fetchWithCache(url, cache))
          );
          route.payload = cache;
        }
        return route;
      }
      return undefined;
    },
  });
