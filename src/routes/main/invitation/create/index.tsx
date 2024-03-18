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
import Create from "./Create";

export default (context: RouteContext<AppRoute, AppContext>) => {
  const success = context.query?.get("success");
  const token = context.query?.get("token");

  if (!success && !token) {
    return {
      redirect: "/invitation/new",
    };
  }

  return {
    component: (
      <LayoutContainer path={context.pathname}>
        <Create success={success} token={token} />
      </LayoutContainer>
    ),
    title: "Invitation",
  };
};
