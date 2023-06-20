import { ThunkAction } from "@reduxjs/toolkit";
import { Action, State } from "../interfaces";
import { removeRestaurant } from "./restaurants";
import { removeTag } from "./tags";
import { changeUserRole, removeUser } from "./users";

const generateConfirmableActions = <
  T extends {
    [K in keyof T]: (
      ...args: Parameters<T[K]>
    ) => ThunkAction<Promise<Action>, State, unknown, Action>;
  }
>(
  actions: T
) => actions;

export const confirmableActions = generateConfirmableActions({
  changeUserRole,
  removeRestaurant,
  removeTag,
  removeUser,
});
