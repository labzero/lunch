import fetch from '../core/fetch';
import ActionTypes from '../constants/ActionTypes';
import { credentials } from '../core/ApiClient';

export function deleteTag(id) {
  return {
    type: ActionTypes.DELETE_TAG,
    id
  };
}

export function tagDeleted(id) {
  return {
    type: ActionTypes.TAG_DELETED,
    id
  };
}

export function removeTag(id) {
  return (dispatch) => {
    dispatch(deleteTag(id));
    return fetch(`/api/tags/${id}`, {
      credentials,
      method: 'delete'
    });
  };
}
