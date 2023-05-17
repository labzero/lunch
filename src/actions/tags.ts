import { ThunkAction } from "@reduxjs/toolkit";
import { credentials, jsonHeaders, processResponse } from "../core/ApiClient";
import { Action, State, Tag } from "../interfaces";

export function invalidateTags(): Action {
  return { type: "INVALIDATE_TAGS" };
}

export function requestTags(): Action {
  return {
    type: "REQUEST_TAGS",
  };
}

export function receiveTags(json: Tag[]): Action {
  return {
    type: "RECEIVE_TAGS",
    items: json,
  };
}

export function fetchTags(): ThunkAction<void, State, unknown, Action> {
  return (dispatch) => {
    dispatch(requestTags());
    return fetch("/api/tags", {
      credentials,
      headers: jsonHeaders,
    })
      .then((response) => processResponse(response, dispatch))
      .then((json) => dispatch(receiveTags(json)));
  };
}

function shouldFetchTags(state: State) {
  const tags = state.tags;
  if (!tags.items) {
    return true;
  }
  if (tags.isFetching) {
    return false;
  }
  return tags.didInvalidate;
}

export function fetchTagsIfNeeded(): ThunkAction<void, State, unknown, Action> {
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

export function deleteTag(id: number): Action {
  return {
    type: "DELETE_TAG",
    id,
  };
}

export function tagDeleted(id: number, userId: number): Action {
  return {
    type: "TAG_DELETED",
    id,
    userId,
  };
}

export function removeTag(
  id: number
): ThunkAction<void, State, unknown, Action> {
  return (dispatch, getState) => {
    dispatch(deleteTag(id));
    return fetch(`/api/tags/${id}`, {
      credentials,
      method: "delete",
    })
      .then((response) => processResponse(response, dispatch))
      .then(() => dispatch(tagDeleted(id, getState().user.id)));
  };
}
