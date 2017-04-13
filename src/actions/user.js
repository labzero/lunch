import ActionTypes from '../constants/ActionTypes';
import { credentials, jsonHeaders, processResponse } from '../core/ApiClient';
import { flashError } from './flash.js';

export function patchCurrentUser(payload) {
  return {
    type: ActionTypes.PATCH_CURRENT_USER,
    payload
  };
}

export function currentUserPatched(user) {
  return {
    type: ActionTypes.CURRENT_USER_PATCHED,
    user
  };
}

export function updateCurrentUser(payload) {
  return (dispatch) => {
    dispatch(patchCurrentUser(payload));
    return fetch('/api/user', {
      method: 'PATCH',
      credentials,
      headers: jsonHeaders,
      body: JSON.stringify(payload)
    })
      .then(response => processResponse(response))
      .then(json => dispatch(currentUserPatched(json)))
      .catch(err => {
        dispatch(flashError(err.message));
        throw err;
      });
  };
}
