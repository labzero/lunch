import queryString from 'query-string';

export default (context) => {
  let stringifiedQuery = queryString.stringify(context.query);
  if (stringifiedQuery) {
    stringifiedQuery = `%3F${stringifiedQuery}`;
  }

  return { redirect: `/login?next=${context.path}${stringifiedQuery}` };
};
