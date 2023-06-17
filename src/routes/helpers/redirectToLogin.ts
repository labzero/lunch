import { AppContext } from "../../interfaces";

export default (context: AppContext) => {
  const stringifiedQuery = context.query?.toString();
  let params = "";
  if (context.path !== "/" || stringifiedQuery) {
    params = `?next=${context.path}`;
    if (stringifiedQuery) {
      params = `${params}%3F${stringifiedQuery}`;
    }
  }

  return { redirect: `/login${params}` };
};
