import { createSelector } from "reselect";
import { State } from "../interfaces";

const emptyObj = {};

export const areUsersLoading = (state: State) => state.users.didInvalidate;
export const getUserId = (state: State, props: { userId: number }) =>
  props.userId;
export const getUserIds = (state: State) => state.users.items.result;
export const getUserEntities = (state: State) =>
  state.users.items.entities.users || emptyObj;

export const getUsers = createSelector(
  getUserIds,
  getUserEntities,
  (ids, entities) => ids.map((id) => entities[id])
);

export const getUserById = (state: State, props: { userId: number } | number) =>
  getUserEntities(state)[typeof props === "object" ? props.userId : props];
