import { ThunkAction } from "@reduxjs/toolkit";
import { canUseDOM } from "fbjs/lib/ExecutionEnvironment";
import { credentials, jsonHeaders, processResponse } from "../core/ApiClient";
import { Action, RoleType, State, Team, User } from "../interfaces";
import { getCurrentUser } from "../selectors/user";

export function invalidateUsers(): Action {
  return { type: "INVALIDATE_USERS" };
}

export function requestUsers(): Action {
  return {
    type: "REQUEST_USERS",
  };
}

export function receiveUsers(json: User[]): Action {
  return {
    type: "RECEIVE_USERS",
    items: json,
  };
}

export function fetchUsers(): ThunkAction<void, State, unknown, Action> {
  return (dispatch) => {
    dispatch(requestUsers());
    return fetch("/api/users", {
      credentials,
      headers: jsonHeaders,
    })
      .then((response) => processResponse(response, dispatch))
      .then((json) => dispatch(receiveUsers(json)));
  };
}

function shouldFetchUsers(state: State) {
  const users = state.users;
  if (!users.items) {
    return true;
  }
  if (users.isFetching) {
    return false;
  }
  return users.didInvalidate;
}

export function fetchUsersIfNeeded(): ThunkAction<
  void,
  State,
  unknown,
  Action
> {
  // Note that the function also receives getState()
  // which lets you choose what to dispatch next.

  // This is useful for avoiding a network request if
  // a cached value is already available.

  return (dispatch, getState) => {
    if (shouldFetchUsers(getState())) {
      // Dispatch a thunk from thunk!
      return dispatch(fetchUsers());
    }

    // Let the calling code know there's nothing to wait for.
    return Promise.resolve();
  };
}

export function deleteUser(id: number, team: Team, isSelf: boolean): Action {
  return {
    type: "DELETE_USER",
    id,
    isSelf,
    team,
  };
}

export function userDeleted(id: number, team: Team, isSelf: boolean): Action {
  return {
    type: "USER_DELETED",
    id,
    isSelf,
    team,
  };
}

export function removeUser(
  id: number,
  team: Team
): ThunkAction<void, State, unknown, Action> {
  return (dispatch, getState) => {
    const state = getState();
    let isSelf = false;
    if (getCurrentUser(state)!.id === id) {
      isSelf = true;
    }
    dispatch(deleteUser(id, team, isSelf));
    let url = `/api/users/${id}`;
    const host = state.host;
    let protocol = "http:";
    if (canUseDOM) {
      protocol = window.location.protocol;
    }
    if (team) {
      url = `${protocol}//${team.slug}.${host}${url}`;
    }
    return fetch(url, {
      credentials: team ? "include" : credentials,
      method: "delete",
    })
      .then((response) => processResponse(response, dispatch))
      .then(() => dispatch(userDeleted(id, team, isSelf)));
  };
}

export function postUser(obj: User): Action {
  return {
    type: "POST_USER",
    user: obj,
  };
}

export function userPosted(json: User): Action {
  return {
    type: "USER_POSTED",
    user: json,
  };
}

export function addUser(
  payload: User
): ThunkAction<void, State, unknown, Action> {
  return (dispatch) => {
    dispatch(postUser(payload));
    return fetch("/api/users", {
      method: "post",
      credentials,
      headers: jsonHeaders,
      body: JSON.stringify(payload),
    })
      .then((response) => processResponse(response, dispatch))
      .then((json) => dispatch(userPosted(json)));
  };
}

export function patchUser(
  id: number,
  roleType: RoleType,
  team: Team,
  isSelf: boolean
): Action {
  return {
    type: "PATCH_USER",
    id,
    isSelf,
    roleType,
    team,
  };
}

export function userPatched(
  id: number,
  user: User,
  team: Team,
  isSelf: boolean
): Action {
  return {
    type: "USER_PATCHED",
    id,
    isSelf,
    team,
    user,
  };
}

export function changeUserRole(
  id: number,
  type: RoleType
): ThunkAction<void, State, unknown, Action> {
  const payload = { id, type };
  return (dispatch, getState) => {
    const state = getState();
    const team = state.team;
    let isSelf = false;
    if (getCurrentUser(state)!.id === id) {
      isSelf = true;
    }
    dispatch(patchUser(id, type, team, isSelf));
    return fetch(`/api/users/${id}`, {
      method: "PATCH",
      credentials,
      headers: jsonHeaders,
      body: JSON.stringify(payload),
    })
      .then((response) => processResponse(response, dispatch))
      .then((json) => dispatch(userPatched(id, json, team, isSelf)));
  };
}
