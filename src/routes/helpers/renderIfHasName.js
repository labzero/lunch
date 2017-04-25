import redirectToLogin from './redirectToLogin';

export default (context, makeRoute) => {
  const state = context.store.getState();
  const user = state.user;
  const host = state.host;

  let redirect = `//${host}/welcome?next=${context.path}`;
  if (context.subdomain) {
    redirect = `${redirect}&team=${context.subdomain}`;
  }

  if (user.id) {
    if (user.name) {
      return makeRoute();
    }
    return {
      redirect
    };
  }
  return redirectToLogin(context);
};
