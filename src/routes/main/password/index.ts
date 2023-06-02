/**
 * React Starter Kit (https://www.reactstarterkit.com/)
 *
 * Copyright © 2014-present Kriasoft, LLC. All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE.txt file in the root directory of this source tree.
 */

/* eslint-disable global-require */

import { AppContext } from "../../../interfaces";
import create from "./create";
import edit from "./edit";
import newAction from "./new";

export default [
  {
    path: "",
    action: create,
  },
  {
    path: "/edit",
    action: edit,
  },
  {
    path: "/new",
    action: newAction,
  },

  // Wildcard routes, e.g. { path: '(.*)', ... } (must go last)
  {
    path: "(.*)",
    action: async (context: AppContext) =>
      (
        await import(/* webpackChunkName: 'not-found' */ "../../not-found")
      ).default(context),
  },
];
