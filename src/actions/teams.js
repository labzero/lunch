import ActionTypes from '../constants/ActionTypes';
import { processResponse, credentials, jsonHeaders } from '../core/ApiClient';
import { flashError } from './flash.js';
import { userRoleAdded } from './users.js';

export function postTeam(obj) {
  return {
    type: ActionTypes.POST_TEAM,
    team: obj
  };
}

export function teamPosted(obj) {
  return {
    type: ActionTypes.TEAM_POSTED,
    team: obj
  };
}

export function createTeam(payload) {
  return (dispatch) => {
    dispatch(postTeam(payload));
    return fetch('/api/teams', {
      method: 'post',
      credentials,
      headers: jsonHeaders,
      body: JSON.stringify(payload)
    })
      .then(response => processResponse(response))
      .then(obj => {
        dispatch(teamPosted(obj));
        if (obj.roles) {
          obj.roles.forEach(role => {
            dispatch(userRoleAdded(role));
          });
        }
      })
      .catch(
        err => dispatch(flashError(err.message))
      );
  };
}
