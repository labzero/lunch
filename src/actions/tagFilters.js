import ActionTypes from '../constants/ActionTypes';

export function addTagFilter(id) {
  return {
    type: ActionTypes.ADD_TAG_FILTER,
    id
  };
}

export function clearTagFilters() {
  return { type: ActionTypes.CLEAR_TAG_FILTERS };
}

export function removeTagFilter(id) {
  return {
    type: ActionTypes.REMOVE_TAG_FILTER,
    id
  };
}
