import { Role, Team, User } from "../interfaces";

export default (user: User, team?: Team | null) => {
  if (!team) {
    return undefined;
  }
  if (user.type) {
    return { type: user.type } as Role;
  }
  return user.roles.find((userRole) => userRole.teamId === team.id);
};
