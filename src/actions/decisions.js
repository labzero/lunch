import ActionTypes from '../constants/ActionTypes';
import { getDecision } from '../selectors/decisions';
import { processResponse, credentials, jsonHeaders } from '../core/ApiClient';

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
      credentials,
      headers: jsonHeaders
    })
      .then(response => processResponse(response, dispatch))
      .then(json => dispatch(receiveDecision(json)));
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

export const decisionPosted = (decision, deselected, userId) => ({
  type: ActionTypes.DECISION_POSTED,
  decision,
  deselected,
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
    .then(response => processResponse(response, dispatch))
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
    .then(response => processResponse(response, dispatch));
};
