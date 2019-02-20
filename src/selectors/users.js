import { createSelector } from 'reselect';

const emptyObj = {};

export const areUsersLoading = state => state.users.didInvalidate;
export const getUserId = (state, props) => props.userId;
export const getUserIds = state => state.users.items.result;
export const getUserEntities = state => state.users.items.entities.users || emptyObj;

export const getUsers = createSelector(getUserIds, getUserEntities,
  (ids, entities) => ids.map(id => entities[id]));

export const getUserById = (state, props) => getUserEntities(state)[typeof props === 'object' ? props.userId : props];
