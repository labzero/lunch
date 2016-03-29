import ActionTypes from '../constants/ActionTypes';
import { scrollToTop } from './pageUi';

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

export function showMapAndInfoWindow(id) {
  return dispatch => {
    dispatch(showInfoWindow(id));
    dispatch(scrollToTop());
  };
}
