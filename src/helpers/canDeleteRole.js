export default (role, roleToDelete) => {
  switch (role) {
    case 'member':
      return roleToDelete === 'guest';
    case 'owner':
      return true;
    default:
      return false;
  }
};
