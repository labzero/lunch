import qs from "qs";

export default (context) => {
  const stringifiedQuery = qs.stringify(context.query);
  let params = "";
  if (context.path !== "/" || stringifiedQuery) {
    params = `?next=${context.path}`;
    if (stringifiedQuery) {
      params = `${params}%3F${stringifiedQuery}`;
    }
  }

  return { redirect: `/login${params}` };
};
