import ActionTypes from '../constants/ActionTypes';
import { credentials, jsonHeaders, processResponse } from '../core/ApiClient';
import { getCurrentUser } from '../selectors/user';
import { flashError } from './flash.js';

export function invalidateUsers() {
  return { type: ActionTypes.INVALIDATE_USERS };
}

export function requestUsers() {
  return {
    type: ActionTypes.REQUEST_USERS
  };
}

export function receiveUsers(json) {
  return {
    type: ActionTypes.RECEIVE_USERS,
    items: json
  };
}

export function fetchUsers() {
  return dispatch => {
    dispatch(requestUsers());
    return fetch('/api/users', {
      credentials
    })
      .then(response => processResponse(response))
      .then(json => dispatch(receiveUsers(json)))
      .catch(
        err => dispatch(flashError(err.message))
      );
  };
}

function shouldFetchUsers(state) {
  const users = state.users;
  if (!users.items) {
    return true;
  }
  if (users.isFetching) {
    return false;
  }
  return users.didInvalidate;
}

export function fetchUsersIfNeeded() {
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

export function deleteUser(id, team, isSelf) {
  return {
    type: ActionTypes.DELETE_USER,
    id,
    isSelf,
    team
  };
}

export function userDeleted(id, team, isSelf) {
  return {
    type: ActionTypes.USER_DELETED,
    id,
    isSelf,
    team
  };
}

export function removeUser(id, team) {
  return (dispatch, getState) => {
    const state = getState();
    let isSelf = false;
    if (getCurrentUser(state).id === id) {
      isSelf = true;
    }
    dispatch(deleteUser(id, team, isSelf));
    let url = `/api/users/${id}`;
    const host = state.host;
    if (team) {
      url = `//${team.slug}.${host}${url}`;
    }
    return fetch(url, {
      credentials: team ? 'include' : credentials,
      method: 'delete'
    })
      .then(response => processResponse(response))
      .then(() => dispatch(userDeleted(id, team, isSelf)))
      .catch(
        err => dispatch(flashError(err.message))
      );
  };
}

export function postUser(id) {
  return {
    type: ActionTypes.POST_USER,
    id
  };
}

export function userPosted(json) {
  return {
    type: ActionTypes.USER_POSTED,
    user: json
  };
}

export function addUser(payload) {
  return (dispatch) => {
    dispatch(postUser(payload));
    return fetch('/api/users', {
      method: 'post',
      credentials,
      headers: jsonHeaders,
      body: JSON.stringify(payload)
    })
      .then(response => processResponse(response))
      .then(json => dispatch(userPosted(json)))
      .catch(
        err => dispatch(flashError(err.message))
      );
  };
}

export function patchUser(id, roleType) {
  return {
    type: ActionTypes.PATCH_USER,
    id,
    roleType
  };
}

export function userPatched(id, json) {
  return {
    type: ActionTypes.USER_PATCHED,
    id,
    user: json
  };
}

export function changeUserRole(id, type) {
  const payload = { id, type };
  return (dispatch) => {
    dispatch(patchUser(id, type));
    return fetch(`/api/users/${id}`, {
      method: 'PATCH',
      credentials,
      headers: jsonHeaders,
      body: JSON.stringify(payload)
    })
      .then(response => processResponse(response))
      .then(json => dispatch(userPatched(id, json)))
      .catch(
        err => dispatch(flashError(err.message))
      );
  };
}
