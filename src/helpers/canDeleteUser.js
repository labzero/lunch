import getRole from './getRole';
import roleCanDeleteRole from './roleCanDeleteRole';

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
  return roleCanDeleteRole(userRole, userToDeleteRole);
};
