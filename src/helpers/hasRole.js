import getRole from './getRole';

export default (user, team, role) => {
  if (!user || !user.id) {
    return false;
  }
  if (user.superuser) {
    return true;
  }
  const teamRole = getRole(user, team);
  if (!teamRole) {
    return false;
  }
  switch (role) {
    case 'admin':
      return teamRole.type === 'admin' || teamRole.type === 'owner';
    case 'owner':
      return teamRole.type === 'owner';
    default:
      return true;
  }
};
