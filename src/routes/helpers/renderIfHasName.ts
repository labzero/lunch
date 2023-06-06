import { AppContext, AppRoute } from "../../interfaces";
import redirectToLogin from "./redirectToLogin";

export default (context: AppContext, makeRoute: () => AppRoute) => {
  const state = context.store.getState();
  const user = state.user;
  const host = state.host;

  let redirect = `//${host}/welcome?next=${context.path}`;
  if (context.subdomain) {
    redirect = `${redirect}&team=${context.subdomain}`;
  }

  if (user) {
    if (user.name) {
      return makeRoute();
    }
    return {
      redirect,
    };
  }
  return redirectToLogin(context);
};
