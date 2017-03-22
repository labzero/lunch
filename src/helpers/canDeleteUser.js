import getRole from './getRole';
import canDeleteRole from './canDeleteRole';

export default (user, userToDelete, team) => {
  if (!user || !user.id) {
    return false;
  }
  if (user.superuser) {
    return true;
  }
  const userRole = getRole(user, team);
  const userToDeleteRole = getRole(userToDelete, team);
  if (!userRole || !userToDeleteRole) {
    return false;
  }
  return canDeleteRole(userRole.type, userToDeleteRole.type);
};
