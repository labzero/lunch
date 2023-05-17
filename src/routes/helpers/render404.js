import React from "react";
import LayoutContainer from "../../components/Layout/LayoutContainer";
import NotFound from "../not-found/NotFound";

const title = "Page not found";

export default (context) => ({
  chunks: ["not-found"],
  title,
  component: (
    <LayoutContainer path={context.pathname}>
      <NotFound title={title} />
    </LayoutContainer>
  ),
  status: 404,
});
