/**
 * React Starter Kit (https://www.reactstarterkit.com/)
 *
 * Copyright © 2014-present Kriasoft, LLC. All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE.txt file in the root directory of this source tree.
 */

import React from "react";
import { RouteContext } from "universal-router";
import LayoutContainer from "../../../../components/Layout/LayoutContainer";
import { AppContext, AppRoute } from "../../../../interfaces";
import render404 from "../../../helpers/render404";
import Create from "./Create";

export default (context: RouteContext<AppRoute, AppContext>) => {
  const state = context.store.getState();
  const user = state.user;

  if (user?.superuser) {
    return {
      component: (
        <LayoutContainer path={context.pathname}>
          <Create />
        </LayoutContainer>
      ),
      title: "New user",
    };
  }

  return render404(context);
};
