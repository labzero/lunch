import ActionTypes from '../constants/ActionTypes';
import { credentials, jsonHeaders, processResponse } from '../core/ApiClient';

export function invalidateTags() {
  return { type: ActionTypes.INVALIDATE_TAGS };
}

export function requestTags() {
  return {
    type: ActionTypes.REQUEST_TAGS
  };
}

export function receiveTags(json) {
  return {
    type: ActionTypes.RECEIVE_TAGS,
    items: json
  };
}

export function fetchTags() {
  return dispatch => {
    dispatch(requestTags());
    return fetch('/api/tags', {
      credentials,
      headers: jsonHeaders
    })
      .then(response => processResponse(response, dispatch))
      .then(json => dispatch(receiveTags(json)));
  };
}

function shouldFetchTags(state) {
  const tags = state.tags;
  if (!tags.items) {
    return true;
  }
  if (tags.isFetching) {
    return false;
  }
  return tags.didInvalidate;
}

export function fetchTagsIfNeeded() {
  // Note that the function also receives getState()
  // which lets you choose what to dispatch next.

  // This is useful for avoiding a network request if
  // a cached value is already available.

  return (dispatch, getState) => {
    if (shouldFetchTags(getState())) {
      // Dispatch a thunk from thunk!
      return dispatch(fetchTags());
    }

    // Let the calling code know there's nothing to wait for.
    return Promise.resolve();
  };
}

export function deleteTag(id) {
  return {
    type: ActionTypes.DELETE_TAG,
    id
  };
}

export function tagDeleted(id, userId) {
  return {
    type: ActionTypes.TAG_DELETED,
    id,
    userId
  };
}

export function removeTag(id) {
  return (dispatch, getState) => {
    dispatch(deleteTag(id));
    return fetch(`/api/tags/${id}`, {
      credentials,
      method: 'delete'
    })
      .then(response => processResponse(response, dispatch))
      .then(() => dispatch(tagDeleted(id, getState().user.id)));
  };
}
