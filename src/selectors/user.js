export const getCurrentUser = state => state.user;
export const getCurrentUserId = state => state.user.id;
export const isLoggedIn = state => state.user.id !== undefined;
