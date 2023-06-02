/**
 * React Starter Kit (https://www.reactstarterkit.com/)
 *
 * Copyright © 2014-present Kriasoft, LLC. All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE.txt file in the root directory of this source tree.
 */

import React from "react";
import LayoutContainer from "../../../../components/Layout/LayoutContainer";
import { AppContext } from "../../../../interfaces";
import renderIfLoggedOut from "../../../helpers/renderIfLoggedOut";
import Edit from "./Edit";

export default (context: AppContext) => {
  const state = context.store.getState();

  const token = context.query?.token as string | undefined;

  return renderIfLoggedOut(state, () => {
    if (!token) {
      return {
        redirect: "/password/new",
      };
    }

    return {
      component: (
        <LayoutContainer path={context.pathname}>
          <Edit token={token} />
        </LayoutContainer>
      ),
      title: "Reset password",
    };
  });
};
