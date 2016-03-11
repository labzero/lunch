import * as ActionTypes from '../ActionTypes';

export function showInfoWindow(id) {
  return {
    type: ActionTypes.SHOW_INFO_WINDOW,
    id
  };
}

export function hideInfoWindow(id) {
  return {
    type: ActionTypes.HIDE_INFO_WINDOW,
    id
  };
}
