export default (role, roleToDelete) => {
  switch (role.type) {
    case 'admin':
      return roleToDelete.type === 'user';
    case 'owner':
      return true;
    default:
      return false;
  }
};
