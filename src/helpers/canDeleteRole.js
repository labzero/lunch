export default (role, roleToDelete) => {
  switch (role) {
    case 'admin':
      return roleToDelete === 'user';
    case 'owner':
      return true;
    default:
      return false;
  }
};
