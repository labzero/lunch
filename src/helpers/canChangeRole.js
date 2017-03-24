export default (role, roleToChange, target) => {
  switch (role) {
    case 'member':
      return roleToChange === 'guest' && target !== 'owner';
    case 'owner':
      return true;
    default:
      return false;
  }
};
