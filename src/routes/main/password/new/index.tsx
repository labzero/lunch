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
import renderIfLoggedOut from "../../../helpers/renderIfLoggedOut";
import New from "./New";

export default (context: RouteContext<AppRoute, AppContext>) => {
  const state = context.store.getState();

  const email = context.query?.get("email");

  return renderIfLoggedOut(state, () => ({
    component: (
      <LayoutContainer path={context.pathname}>
        <New email={email} />
      </LayoutContainer>
    ),
    title: "Reset password",
  }));
};
