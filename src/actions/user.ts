import { ThunkAction } from "@reduxjs/toolkit";
import { credentials, jsonHeaders, processResponse } from "../core/ApiClient";
import { Action, State, User } from "../interfaces";

export function patchCurrentUser(payload: User): Action {
  return {
    type: "PATCH_CURRENT_USER",
    payload,
  };
}

export function currentUserPatched(user: User): Action {
  return {
    type: "CURRENT_USER_PATCHED",
    user,
  };
}

export function updateCurrentUser(
  payload: User
): ThunkAction<void, State, unknown, Action> {
  return (dispatch) => {
    dispatch(patchCurrentUser(payload));
    return fetch("/api/user", {
      method: "PATCH",
      credentials,
      headers: jsonHeaders,
      body: JSON.stringify(payload),
    })
      .then((response) => processResponse(response, dispatch))
      .then((json) => dispatch(currentUserPatched(json)));
  };
}
