import ActionTypes from '../constants/ActionTypes';

export function showTagFilterForm() {
  return { type: ActionTypes.SHOW_TAG_FILTER_FORM };
}

export function hideTagFilterForm() {
  return { type: ActionTypes.HIDE_TAG_FILTER_FORM };
}
