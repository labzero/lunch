import fetch from '../core/fetch';
import ActionTypes from '../constants/ActionTypes';
import { getDecision } from '../selectors/decisions';
import { processResponse, credentials, jsonHeaders } from '../core/ApiClient';
import { flashError } from './flash.js';

export const postDecision = (restaurantId) => ({
  type: ActionTypes.POST_DECISION,
  restaurantId
});

export const decisionPosted = (decision, userId) => ({
  type: ActionTypes.DECISION_POSTED,
  decision,
  userId
});

export const deleteDecision = restaurantId => ({
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
  fetch('/api/decisions', {
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
  fetch('/api/decisions/', {
    credentials,
    headers: jsonHeaders,
    method: 'delete',
    body: JSON.stringify(payload)
  });
};
