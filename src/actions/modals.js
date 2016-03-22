import ActionTypes from '../constants/ActionTypes';

export function showModal(name, opts) {
  return {
    type: ActionTypes.SHOW_MODAL,
    name,
    opts
  };
}

export function hideModal(name) {
  return {
    type: ActionTypes.HIDE_MODAL,
    name
  };
}
