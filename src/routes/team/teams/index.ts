/**
 * React Starter Kit (https://www.reactstarterkit.com/)
 *
 * Copyright © 2014-present Kriasoft, LLC. All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE.txt file in the root directory of this source tree.
 */

import { RouteContext } from "universal-router";
import hasRole from "../../../helpers/hasRole";
import { AppContext, AppRoute } from "../../../interfaces";
import renderIfHasName from "../../helpers/renderIfHasName";
import render404 from "../../helpers/render404";

export default (context: RouteContext<AppRoute, AppContext>) => {
  const state = context.store.getState();
  const host = state.host;
  const team = state.team;
  const user = state.user;

  return renderIfHasName(context, () => {
    if (team && hasRole(user, team)) {
      return {
        redirect: `//${host}/teams`,
        status: 301,
      };
    }
    return render404(context);
  });
};
