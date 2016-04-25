import ActionTypes from '../constants/ActionTypes';

export function addTagExclusion(id) {
  return {
    type: ActionTypes.ADD_TAG_EXCLUSION,
    id
  };
}

export function removeTagExclusion(id) {
  return {
    type: ActionTypes.REMOVE_TAG_EXCLUSION,
    id
  };
}
