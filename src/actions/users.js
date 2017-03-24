import ActionTypes from '../constants/ActionTypes';
import { credentials, jsonHeaders, processResponse } from '../core/ApiClient';
import { flashError } from './flash.js';

export function invalidateUsers() {
  return { type: ActionTypes.INVALIDATE_USERS };
}

export function requestUsers(teamSlug) {
  return {
    type: ActionTypes.REQUEST_USERS,
    teamSlug
  };
}

export function receiveUsers(json, teamSlug) {
  return {
    type: ActionTypes.RECEIVE_USERS,
    items: json,
    teamSlug
  };
}

export function fetchUsers(teamSlug) {
  return dispatch => {
    dispatch(requestUsers(teamSlug));
    return fetch(`/api/teams/${teamSlug}/users`, {
      credentials
    })
      .then(response => processResponse(response))
      .then(json => dispatch(receiveUsers(json, teamSlug)))
      .catch(
        err => dispatch(flashError(err.message))
      );
  };
}

function shouldFetchUsers(state, teamSlug) {
  const restaurants = state.restaurants;
  if (restaurants.teamSlug !== teamSlug) {
    return true;
  }
  if (!restaurants.items) {
    return true;
  }
  if (restaurants.isFetching) {
    return false;
  }
  return restaurants.didInvalidate;
}

export function fetchUsersIfNeeded(teamSlug) {
  // Note that the function also receives getState()
  // which lets you choose what to dispatch next.

  // This is useful for avoiding a network request if
  // a cached value is already available.

  return (dispatch, getState) => {
    if (shouldFetchUsers(getState(), teamSlug)) {
      // Dispatch a thunk from thunk!
      return dispatch(fetchUsers(teamSlug));
    }

    // Let the calling code know there's nothing to wait for.
    return Promise.resolve();
  };
}

export function deleteUser(teamSlug, id) {
  return {
    type: ActionTypes.DELETE_USER,
    id,
    teamSlug
  };
}

export function userDeleted(id, userId) {
  return {
    type: ActionTypes.USER_DELETED,
    id,
    userId
  };
}

export function removeUser(teamSlug, id) {
  return (dispatch) => {
    dispatch(deleteUser(teamSlug, id));
    return fetch(`/api/teams/${teamSlug}/users/${id}`, {
      credentials,
      method: 'delete'
    })
      .then(response => processResponse(response))
      .then(() => dispatch(userDeleted(id, teamSlug)))
      .catch(
        err => dispatch(flashError(err.message))
      );
  };
}

export function postUser(teamSlug, id) {
  return {
    type: ActionTypes.POST_USER,
    id,
    teamSlug
  };
}

export function userPosted(json, teamSlug) {
  return {
    type: ActionTypes.USER_POSTED,
    user: json,
    teamSlug
  };
}

export function addUser(teamSlug, payload) {
  return (dispatch) => {
    dispatch(postUser(teamSlug, payload));
    return fetch(`/api/teams/${teamSlug}/users`, {
      method: 'post',
      credentials,
      headers: jsonHeaders,
      body: JSON.stringify(payload)
    })
      .then(response => processResponse(response))
      .then(json => dispatch(userPosted(json, teamSlug)))
      .catch(
        err => dispatch(flashError(err.message))
      );
  };
}

export function patchUser(teamSlug, id, roleType) {
  return {
    type: ActionTypes.PATCH_USER,
    id,
    roleType,
    teamSlug
  };
}

export function userPatched(id, json, teamSlug) {
  return {
    type: ActionTypes.USER_PATCHED,
    id,
    user: json,
    teamSlug
  };
}

export function changeUserRole(teamSlug, id, type) {
  const payload = { id, type };
  return (dispatch) => {
    dispatch(patchUser(teamSlug, id, type));
    return fetch(`/api/teams/${teamSlug}/users/${id}`, {
      method: 'PATCH',
      credentials,
      headers: jsonHeaders,
      body: JSON.stringify(payload)
    })
      .then(response => processResponse(response))
      .then(json => dispatch(userPatched(id, json, teamSlug)))
      .catch(
        err => dispatch(flashError(err.message))
      );
  };
}
