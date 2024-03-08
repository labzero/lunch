/**
 * React Starter Kit (https://www.reactstarterkit.com/)
 *
 * Copyright © 2014-present Kriasoft, LLC. All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE.txt file in the root directory of this source tree.
 */

/* eslint-disable global-require */
import { Route } from "universal-router";
import { AppContext, AppRoute } from "src/interfaces";
import rootAction from "../helpers/rootAction";

// The top-level (parent) route
const team: Route<AppRoute, AppContext> = {
  path: "",

  // Keep in mind, routes are evaluated in order
  children: [
    {
      path: "",
      action: async (context) =>
        (await import(/* webpackChunkName: 'home' */ "./home")).default(
          context
        ),
    },
    {
      path: "/team",
      action: async (context) =>
        (await import(/* webpackChunkName: 'team' */ "./team")).default(
          context
        ),
    },
    {
      path: "/tags",
      action: async (context) =>
        (await import(/* webpackChunkName: 'tags' */ "./tags")).default(
          context
        ),
    },
    {
      path: "/teams",
      action: async (context) =>
        (await import(/* webpackChunkName: 'teams' */ "./teams")).default(
          context
        ),
    },
    {
      path: "/login",
      action: async (context) =>
        (await import(/* webpackChunkName: 'login' */ "../login")).default(
          context
        ),
    },

    // Wildcard routes, e.g. { path: '(.*)', ... } (must go last)
    {
      path: "(.*)",
      action: async (context) =>
        (
          await import(/* webpackChunkName: 'not-found' */ "../not-found")
        ).default(context),
    },
  ],

  action: rootAction,
};

export default team;
