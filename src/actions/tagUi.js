import ActionTypes from '../constants/ActionTypes';

export function showTagFilterForm() {
  return { type: ActionTypes.SHOW_TAG_FILTER_FORM };
}

export function hideTagFilterForm() {
  return { type: ActionTypes.HIDE_TAG_FILTER_FORM };
}

export function setTagFilterAutosuggestValue(value) {
  return {
    type: ActionTypes.SET_TAG_FILTER_AUTOSUGGEST_VALUE,
    value
  };
}

export function showTagExclusionForm() {
  return { type: ActionTypes.SHOW_TAG_EXCLUSION_FORM };
}

export function hideTagExclusionForm() {
  return { type: ActionTypes.HIDE_TAG_EXCLUSION_FORM };
}

export function setTagExclusionAutosuggestValue(value) {
  return {
    type: ActionTypes.SET_TAG_EXCLUSION_AUTOSUGGEST_VALUE,
    value
  };
}
