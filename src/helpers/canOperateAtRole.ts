import { RoleType } from "../interfaces";

export default (currentRole: RoleType, target?: RoleType) => {
  switch (target) {
    case "member":
      return currentRole === "member" || currentRole === "owner";
    case "owner":
      return currentRole === "owner";
    default:
      return true;
  }
};
