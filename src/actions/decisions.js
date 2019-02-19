import ActionTypes from '../constants/ActionTypes';
import { processResponse, credentials, jsonHeaders } from '../core/ApiClient';

export function invalidateDecisions() {
  return { type: ActionTypes.INVALIDATE_DECISIONS };
}

export function requestDecisions() {
  return {
    type: ActionTypes.REQUEST_DECISIONS
  };
}

export function receiveDecisions(json) {
  return {
    type: ActionTypes.RECEIVE_DECISIONS,
    items: json
  };
}

export function fetchDecisions() {
  return dispatch => {
    dispatch(requestDecisions());
    return fetch('/api/decisions/', {
      credentials,
      headers: jsonHeaders
    })
      .then(response => processResponse(response, dispatch))
      .then(json => dispatch(receiveDecisions(json)));
  };
}

function shouldFetchDecisions(state) {
  const { decisions } = state;
  if (decisions.isFetching) {
    return false;
  }
  return decisions.didInvalidate;
}

export function fetchDecisionsIfNeeded() {
  // Note that the function also receives getState()
  // which lets you choose what to dispatch next.

  // This is useful for avoiding a network request if
  // a cached value is already available.

  return (dispatch, getState) => {
    if (shouldFetchDecisions(getState())) {
      // Dispatch a thunk from thunk!
      return dispatch(fetchDecisions());
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

export const deleteDecision = () => ({
  type: ActionTypes.DELETE_DECISION,
});

export const decisionsDeleted = (decisions, userId) => ({
  type: ActionTypes.DECISIONS_DELETED,
  decisions,
  userId
});

export const decide = (restaurantId, daysAgo) => dispatch => {
  const payload = { daysAgo, restaurant_id: restaurantId };
  dispatch(postDecision(restaurantId));
  return fetch('/api/decisions', {
    credentials,
    headers: jsonHeaders,
    method: 'post',
    body: JSON.stringify(payload)
  })
    .then(response => processResponse(response, dispatch));
};

export const removeDecision = () => (dispatch) => {
  dispatch(deleteDecision());
  return fetch('/api/decisions/fromToday', {
    credentials,
    headers: jsonHeaders,
    method: 'delete',
  })
    .then(response => processResponse(response, dispatch));
};
