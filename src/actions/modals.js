import ActionTypes from '../constants/ActionTypes';

export function showModal(name, restaurantId) {
  return {
    type: ActionTypes.SHOW_MODAL,
    name,
    restaurantId
  };
}

export function hideModal(name) {
  return {
    type: ActionTypes.HIDE_MODAL,
    name
  };
}
