export default (role, roleToChange, target) => {
  switch (role) {
    case 'member':
      return roleToChange === 'guest' && target === 'member';
    case 'owner':
      return true;
    default:
      return false;
  }
};
