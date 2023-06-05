import React from "react";
import LayoutContainer from "../../components/Layout/LayoutContainer";
import { AppContext } from "../../interfaces";
import NotFound from "../not-found/NotFound";

const title = "Page not found";

export default (context: AppContext) => ({
  chunks: ["not-found"],
  title,
  component: (
    <LayoutContainer path={context.pathname}>
      <NotFound title={title} />
    </LayoutContainer>
  ),
  status: 404,
});
