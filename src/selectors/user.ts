import { State } from "../interfaces";

export const getCurrentUser = (state: State) => state.user;
export const getCurrentUserId = (state: State) => state.user?.id;
export const isLoggedIn = (state: State) => state.user !== null;
