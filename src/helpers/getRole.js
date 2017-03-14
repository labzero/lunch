export default (user, team) => {
  if (!team) {
    return undefined;
  }
  return user.roles.find(userRole => userRole.team_id === team.id);
};
