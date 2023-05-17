export default (currentRole, target) => {
  switch (target) {
    case "member":
      return currentRole === "member" || currentRole === "owner";
    case "owner":
      return currentRole === "owner";
    default:
      return true;
  }
};
