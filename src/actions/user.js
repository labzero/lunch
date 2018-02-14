import ActionTypes from '../constants/ActionTypes';
import { credentials, jsonHeaders, processResponse } from '../core/ApiClient';

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
      .then(response => processResponse(response, dispatch))
      .then(json => dispatch(currentUserPatched(json)));
  };
}
