import { RoleType, Team, User } from "src/interfaces";
import canOperateAtRole from "./canOperateAtRole";
import getRole from "./getRole";

export default (
  user: User | null | undefined,
  team: Team | undefined,
  role?: RoleType,
  ignoreSuperuser?: boolean
) => {
  if (!user || !user.id) {
    return false;
  }
  if (!ignoreSuperuser && user.superuser) {
    return true;
  }
  const currentRole = getRole(user, team);
  if (!currentRole) {
    return false;
  }
  return canOperateAtRole(currentRole.type, role);
};
