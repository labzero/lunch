import { getTeams } from "../../selectors/teams";

export default (state, makeRoute) => {
  const user = state.user;
  const host = state.host;

  if (user) {
    if (user.roles.length === 1) {
      const team = getTeams(state)[0];
      if (team) {
        return {
          redirect: `//${team.slug}.${host}`,
        };
      }
    }
    return {
      redirect: "/teams",
    };
  }
  return makeRoute();
};
