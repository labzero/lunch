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
import Create from "./Create";

export default (context) => {
  const success = context.query.success;
  const token = context.query.token;

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
