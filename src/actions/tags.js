import fetch from '../core/fetch';
import ActionTypes from '../constants/ActionTypes';
import { credentials, processResponse } from '../core/ApiClient';
import { flashError } from './flash';

export function invalidateTags() {
  return { type: ActionTypes.INVALIDATE_TAGS };
}

export function requestTags(teamSlug) {
  return {
    type: ActionTypes.REQUEST_TAGS,
    teamSlug
  };
}

export function receiveTags(json, teamSlug) {
  return {
    type: ActionTypes.RECEIVE_TAGS,
    items: json,
    teamSlug
  };
}

function fetchTags(teamSlug) {
  return dispatch => {
    dispatch(requestTags(teamSlug));
    return fetch(`/api/teams/${teamSlug}/tags`, {
      credentials
    })
      .then(response => processResponse(response))
      .then(json => dispatch(receiveTags(json, teamSlug)))
      .catch(
        err => dispatch(flashError(err.message))
      );
  };
}

function shouldFetchTags(state, teamSlug) {
  const restaurants = state.restaurants;
  if (restaurants.teamSlug !== teamSlug) {
    return true;
  }
  if (!restaurants.items) {
    return true;
  }
  if (restaurants.isFetching) {
    return false;
  }
  return restaurants.didInvalidate;
}

export function fetchTagsIfNeeded(teamSlug) {
  // Note that the function also receives getState()
  // which lets you choose what to dispatch next.

  // This is useful for avoiding a network request if
  // a cached value is already available.

  return (dispatch, getState) => {
    if (shouldFetchTags(getState(), teamSlug)) {
      // Dispatch a thunk from thunk!
      return dispatch(fetchTags(teamSlug));
    }

    // Let the calling code know there's nothing to wait for.
    return Promise.resolve();
  };
}

export function deleteTag(teamSlug, id) {
  return {
    type: ActionTypes.DELETE_TAG,
    id,
    teamSlug
  };
}

export function tagDeleted(id, userId) {
  return {
    type: ActionTypes.TAG_DELETED,
    id,
    userId
  };
}

export function removeTag(teamSlug, id) {
  return (dispatch) => {
    dispatch(deleteTag(teamSlug, id));
    return fetch(`/api/teams/${teamSlug}/tags/${id}`, {
      credentials,
      method: 'delete'
    })
      .then(response => processResponse(response))
      .catch(
        err => dispatch(flashError(err.message))
      );
  };
}
