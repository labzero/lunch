import React from "react";
import { RouteContext } from "universal-router";
import LayoutContainer from "../../../components/Layout/LayoutContainer";
import { AppContext, AppRoute } from "../../../interfaces";
import renderIfHasName from "../../helpers/renderIfHasName";
import TeamsContainer from "./TeamsContainer";

/* eslint-disable global-require */

export default (context: RouteContext<AppRoute, AppContext>) =>
  renderIfHasName(context, () => ({
    chunks: ["teams"],
    component: (
      <LayoutContainer path={context.pathname}>
        <TeamsContainer />
      </LayoutContainer>
    ),
    title: "My teams",
  }));
