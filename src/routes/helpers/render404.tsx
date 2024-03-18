import React from "react";
import { RouteContext } from "universal-router";
import LayoutContainer from "../../components/Layout/LayoutContainer";
import { AppContext, AppRoute } from "../../interfaces";
import NotFound from "../not-found/NotFound";

const title = "Page not found";

export default (context: RouteContext<AppRoute, AppContext>) => ({
  chunks: ["not-found"],
  title,
  component: (
    <LayoutContainer path={context.pathname}>
      <NotFound title={title} />
    </LayoutContainer>
  ),
  status: 404,
});
