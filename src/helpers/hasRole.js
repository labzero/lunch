import canOperateAtRole from './canOperateAtRole';
import getRole from './getRole';

export default (user, team, role) => {
  if (!user || !user.id) {
    return false;
  }
  if (user.superuser) {
    return true;
  }
  const currentRole = getRole(user, team);
  if (!currentRole) {
    return false;
  }
  return canOperateAtRole(currentRole.type, role);
};
