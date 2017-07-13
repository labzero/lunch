import ActionTypes from '../constants/ActionTypes';

export function setEditNameFormValue(id, value) {
  return {
    type: ActionTypes.SET_EDIT_NAME_FORM_VALUE,
    id,
    value
  };
}

export function showEditNameForm(id) {
  return {
    type: ActionTypes.SHOW_EDIT_NAME_FORM,
    id
  };
}

export function hideEditNameForm(id) {
  return dispatch => {
    dispatch(setEditNameFormValue(id, ''));
    dispatch({
      type: ActionTypes.HIDE_EDIT_NAME_FORM,
      id
    });
  };
}

export function setFlipMove(val) {
  return {
    type: ActionTypes.SET_FLIP_MOVE,
    val,
  };
}
