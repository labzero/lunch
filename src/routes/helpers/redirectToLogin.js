import queryString from "query-string";

export default (context) => {
  const stringifiedQuery = queryString.stringify(context.query);
  let params = "";
  if (context.path !== "/" || stringifiedQuery) {
    params = `?next=${context.path}`;
    if (stringifiedQuery) {
      params = `${params}%3F${stringifiedQuery}`;
    }
  }

  return { redirect: `/login${params}` };
};
