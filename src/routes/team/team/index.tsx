/**
 * React Starter Kit (https://www.reactstarterkit.com/)
 *
 * Copyright © 2014-present Kriasoft, LLC. All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE.txt file in the root directory of this source tree.
 */

import React from "react";
import LayoutContainer from "../../../components/Layout/LayoutContainer";
import hasRole from "../../../helpers/hasRole";
import { AppContext } from "../../../interfaces";
import renderIfHasName from "../../helpers/renderIfHasName";
import render404 from "../../helpers/render404";
import TeamContainer from "./TeamContainer";

const title = "Team";

export default (context: AppContext) => {
  const state = context.store.getState();
  const user = state.user;
  const team = state.team;

  return renderIfHasName(context, () => {
    if (team && hasRole(user, team, "member")) {
      return {
        title,
        chunks: ["team"],
        component: (
          <LayoutContainer path={context.pathname}>
            <TeamContainer />
          </LayoutContainer>
        ),
        map: hasRole(user, team, "owner"),
      };
    }
    return render404(context);
  });
};
