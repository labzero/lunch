export const getUserId = (state, props) => props.userId;
export const getUserIds = state => state.users.items.result;
export const getUserEntities = state => state.users.items.entities.users;
export const getUserById = (state, props) =>
  getUserEntities(state)[typeof props === 'object' ? props.userId : props];
