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
import New from "./New";

export default (context: AppContext) => {
  const email = context.query?.get("email");

  return {
    component: (
      <LayoutContainer path={context.pathname}>
        <New email={email} />
      </LayoutContainer>
    ),
    title: "Invitation",
  };
};
