import React from "react";
import { RouteContext } from "universal-router";
import LayoutContainer from "../../../components/Layout/LayoutContainer";
import render404 from "../../helpers/render404";
import { AppContext, AppRoute } from "../../../interfaces";
import AdminContainer from "./AdminContainer";

/* eslint-disable global-require */

export default (context: RouteContext<AppRoute, AppContext>) => {
  const state = context.store.getState();
  const user = state.user;

  if (user?.superuser) {
    return {
      chunks: ["admin"],
      component: (
        <LayoutContainer path={context.pathname}>
          <AdminContainer />
        </LayoutContainer>
      ),
      queries: ["/api/teams/all"],
    };
  }
  return render404(context);
};
