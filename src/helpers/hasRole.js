import canOperateAtRole from './canOperateAtRole';
import getRole from './getRole';

export default (user, team, role, ignoreSuperuser) => {
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
