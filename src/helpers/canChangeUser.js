import getRole from './getRole';
import canChangeRole from './canChangeRole';

export default (user, userToChange, team, users) => {
  if (!user || !user.id) {
    return false;
  }
  if (user.superuser) {
    return true;
  }
  const userRole = getRole(user, team);
  const userToChangeRole = getRole(userToChange, team);
  if (!userRole || !userToChangeRole) {
    return false;
  }
  if (userRole.type === 'owner' && user.id === userToChange.id) {
    const otherOwners = users.some(otherUser => otherUser.type === 'owner' && otherUser.id !== user.id);

    if (!otherOwners) {
      return false;
    }
  }
  return canChangeRole(userRole.type, userToChangeRole.type);
};
