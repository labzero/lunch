export default async ({ next }) => {
  // Execute each child route until one of them return the result
  const route = await next(true);

  // Provide default values for title, description etc.
  const title = "Lunch";
  if (route.fullTitle) {
    route.title = route.fullTitle;
  } else if (route.title) {
    route.title = `${title} | ${route.title}`;
  } else {
    route.title = title;
  }
  route.description = route.description || "";

  return route;
};
