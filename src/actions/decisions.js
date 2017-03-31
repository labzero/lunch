import ActionTypes from '../constants/ActionTypes';
import { getDecision } from '../selectors/decisions';
import { processResponse, credentials, jsonHeaders } from '../core/ApiClient';
import { flashError } from './flash.js';

export function invalidateDecision() {
  return { type: ActionTypes.INVALIDATE_DECISION };
}

export function requestDecision() {
  return {
    type: ActionTypes.REQUEST_DECISION
  };
}

export function receiveDecision(json) {
  return {
    type: ActionTypes.RECEIVE_DECISION,
    inst: json
  };
}

export function fetchDecision() {
  return dispatch => {
    dispatch(requestDecision());
    return fetch('/api/decisions/fromToday', {
      credentials
    })
      .then(response => processResponse(response))
      .then(json => dispatch(receiveDecision(json)))
      .catch(
        err => dispatch(flashError(err.message))
      );
  };
}

function shouldFetchDecision(state) {
  const restaurants = state.restaurants;
  if (restaurants.isFetching) {
    return false;
  }
  return restaurants.didInvalidate;
}

export function fetchDecisionIfNeeded() {
  // Note that the function also receives getState()
  // which lets you choose what to dispatch next.

  // This is useful for avoiding a network request if
  // a cached value is already available.

  return (dispatch, getState) => {
    if (shouldFetchDecision(getState())) {
      // Dispatch a thunk from thunk!
      return dispatch(fetchDecision());
    }

    // Let the calling code know there's nothing to wait for.
    return Promise.resolve();
  };
}

export const postDecision = (restaurantId) => ({
  type: ActionTypes.POST_DECISION,
  restaurantId
});

export const decisionPosted = (decision, userId) => ({
  type: ActionTypes.DECISION_POSTED,
  decision,
  userId
});

export const deleteDecision = (restaurantId) => ({
  type: ActionTypes.DELETE_DECISION,
  restaurantId
});

export const decisionDeleted = (restaurantId, userId) => ({
  type: ActionTypes.DECISION_DELETED,
  restaurantId,
  userId
});

export const decide = (restaurantId) => dispatch => {
  const payload = { restaurant_id: restaurantId };
  dispatch(postDecision(restaurantId));
  return fetch('/api/decisions', {
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

export const removeDecision = () => (dispatch, getState) => {
  const restaurantId = getDecision(getState()).restaurant_id;
  const payload = { restaurant_id: restaurantId };
  dispatch(deleteDecision(restaurantId));
  return fetch('/api/decisions/fromToday', {
    credentials,
    headers: jsonHeaders,
    method: 'delete',
    body: JSON.stringify(payload)
  })
    .then(response => processResponse(response))
    .catch(
      err => dispatch(flashError(err.message))
    );
};
