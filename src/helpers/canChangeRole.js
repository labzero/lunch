export default (role, roleToChange) => {
  switch (role) {
    case 'member':
      return roleToChange === 'guest';
    case 'owner':
      return true;
    default:
      return false;
  }
};
