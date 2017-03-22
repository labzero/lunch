export default (currentRole, target) => {
  switch (target) {
    case 'admin':
      return currentRole === 'admin' || currentRole === 'owner';
    case 'owner':
      return currentRole === 'owner';
    default:
      return true;
  }
};
