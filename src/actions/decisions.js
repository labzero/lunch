import fetch from '../core/fetch';
import ActionTypes from '../constants/ActionTypes';
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

export const deleteDecision = () => ({
  type: ActionTypes.DELETE_DECISION
});

export const decisionDeleted = (userId) => ({
  type: ActionTypes.DECISION_DELETED,
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

export const removeDecision = () => dispatch => {
  dispatch(deleteDecision());
  fetch('/api/decisions', {
    credentials,
    method: 'delete'
  });
};
