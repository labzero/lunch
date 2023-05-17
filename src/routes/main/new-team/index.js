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
import renderIfHasName from "../../helpers/renderIfHasName";
import NewTeamContainer from "./NewTeamContainer";

const title = "New team";

export default (context) =>
  renderIfHasName(context, () => ({
    title,
    chunks: ["map", "new-team"],
    component: (
      <LayoutContainer path={context.pathname}>
        <NewTeamContainer />
      </LayoutContainer>
    ),
  }));
