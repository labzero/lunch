import fetch from '../core/fetch';
import ActionTypes from '../constants/ActionTypes';
import { getDecision } from '../selectors/decisions';
import { processResponse, credentials, jsonHeaders } from '../core/ApiClient';
import { flashError } from './flash.js';

export function invalidateDecision() {
  return { type: ActionTypes.INVALIDATE_DECISION };
}

export function requestDecision(teamSlug) {
  return {
    type: ActionTypes.REQUEST_DECISION,
    teamSlug
  };
}

export function receiveDecision(json, teamSlug) {
  return {
    type: ActionTypes.RECEIVE_DECISION,
    inst: json,
    teamSlug
  };
}

function fetchDecision(teamSlug) {
  return dispatch => {
    dispatch(requestDecision(teamSlug));
    return fetch(`/api/teams/${teamSlug}/decisions/fromToday`, {
      credentials
    })
      .then(response => processResponse(response))
      .then(json => dispatch(receiveDecision(json, teamSlug)));
  };
}

function shouldFetchDecision(state, teamSlug) {
  const restaurants = state.restaurants;
  if (restaurants.teamSlug !== teamSlug) {
    return true;
  }
  if (restaurants.isFetching) {
    return false;
  }
  return restaurants.didInvalidate;
}

export function fetchDecisionIfNeeded(teamSlug) {
  // Note that the function also receives getState()
  // which lets you choose what to dispatch next.

  // This is useful for avoiding a network request if
  // a cached value is already available.

  return (dispatch, getState) => {
    if (shouldFetchDecision(getState(), teamSlug)) {
      // Dispatch a thunk from thunk!
      return dispatch(fetchDecision(teamSlug));
    }

    // Let the calling code know there's nothing to wait for.
    return Promise.resolve();
  };
}

export const postDecision = (teamSlug, restaurantId) => ({
  type: ActionTypes.POST_DECISION,
  restaurantId,
  teamSlug
});

export const decisionPosted = (decision, userId) => ({
  type: ActionTypes.DECISION_POSTED,
  decision,
  userId
});

export const deleteDecision = (teamSlug, restaurantId) => ({
  type: ActionTypes.DELETE_DECISION,
  restaurantId,
  teamSlug
});

export const decisionDeleted = (restaurantId, userId) => ({
  type: ActionTypes.DECISION_DELETED,
  restaurantId,
  userId
});

export const decide = (teamSlug, restaurantId) => dispatch => {
  const payload = { restaurant_id: restaurantId };
  dispatch(postDecision(teamSlug, restaurantId));
  fetch(`/api/teams/${teamSlug}/decisions`, {
    credentials,
    headers: jsonHeaders,
    method: 'post',
    body: JSON.stringify(payload)
  })
    .then(response => processResponse(response))
    .catch(
      err => dispatch(flashError(err.message))
    );
};

export const removeDecision = teamSlug => (dispatch, getState) => {
  const restaurantId = getDecision(getState()).restaurant_id;
  const payload = { restaurant_id: restaurantId };
  dispatch(deleteDecision(teamSlug, restaurantId));
  fetch(`/api/teams/${teamSlug}/decisions/fromToday`, {
    credentials,
    headers: jsonHeaders,
    method: 'delete',
    body: JSON.stringify(payload)
  });
};
