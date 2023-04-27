import { ThunkAction } from '@reduxjs/toolkit';
import { processResponse, credentials, jsonHeaders } from '../core/ApiClient';
import { Action, Decision, State } from '../interfaces';

export function invalidateDecisions() {
  return { type: "INVALIDATE_DECISIONS" };
}

export function requestDecisions(): Action {
  return {
    type: "REQUEST_DECISIONS"
  };
}

export function receiveDecisions(json: Decision[]): Action {
  return {
    type: "RECEIVE_DECISIONS",
    items: json
  };
}

export function fetchDecisions(): ThunkAction<Promise<Action>, State, unknown, Action> {
  return (dispatch) => {
    dispatch(requestDecisions());
    return fetch('/api/decisions/', {
      credentials,
      headers: jsonHeaders
    })
      .then(response => processResponse(response, dispatch))
      .then(json => dispatch(receiveDecisions(json)));
  };
}

export const postDecision = (restaurantId: number): Action => ({
  type: "POST_DECISION",
  restaurantId
});

export const decisionPosted = (decision: Decision, deselected: Decision[], userId: number): Action => ({
  type: "DECISION_POSTED",
  decision,
  deselected,
  userId
});

export const deleteDecision = (): Action => ({
  type: "DELETE_DECISION",
});

export const decisionsDeleted = (decisions: Decision[], userId: number): Action => ({
  type: "DECISIONS_DELETED",
  decisions,
  userId
});

export const decide = (restaurantId: number, daysAgo?: number): ThunkAction<Promise<Decision>, State, unknown, Action> => dispatch => {
  const payload = { daysAgo, restaurantId };
  dispatch(postDecision(restaurantId));
  return fetch('/api/decisions', {
    credentials,
    headers: jsonHeaders,
    method: 'post',
    body: JSON.stringify(payload)
  })
    .then(response => processResponse(response, dispatch));
};

export const removeDecision = (): ThunkAction<Promise<void>, State, unknown, Action> => (dispatch) => {
  dispatch(deleteDecision());
  return fetch('/api/decisions/fromToday', {
    credentials,
    headers: jsonHeaders,
    method: 'delete',
  })
    .then(response => processResponse(response, dispatch));
};
