import { RoleType } from "../interfaces";

export default (role: RoleType, roleToChange: RoleType, target?: RoleType) => {
  switch (role) {
    case "member":
      return roleToChange === "guest" && target !== "owner";
    case "owner":
      return true;
    default:
      return false;
  }
};
