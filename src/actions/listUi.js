import ActionTypes from '../constants/ActionTypes';

export function setAddTagAutosuggestValue(id, value) {
  return {
    type: ActionTypes.SET_ADD_TAG_AUTOSUGGEST_VALUE,
    id,
    value
  };
}

export function showAddTagForm(id) {
  return {
    type: ActionTypes.SHOW_ADD_TAG_FORM,
    id
  };
}

export function hideAddTagForm(id) {
  return dispatch => {
    dispatch(setAddTagAutosuggestValue(id, ''));
    dispatch({
      type: ActionTypes.HIDE_ADD_TAG_FORM,
      id
    });
  };
}
