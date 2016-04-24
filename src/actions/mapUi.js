import ActionTypes from '../constants/ActionTypes';
import { scrollToTop } from './pageUi';

export function clearCenter() {
  return {
    type: ActionTypes.CLEAR_CENTER
  };
}

export function showInfoWindow(id, latLng) {
  return {
    type: ActionTypes.SHOW_INFO_WINDOW,
    id,
    latLng
  };
}

export function hideInfoWindow(id) {
  return {
    type: ActionTypes.HIDE_INFO_WINDOW,
    id
  };
}

export function hideAllInfoWindows() {
  return {
    type: ActionTypes.HIDE_ALL_INFO_WINDOWS
  };
}

export function showMapAndInfoWindow(id, latLng) {
  return dispatch => {
    dispatch(showInfoWindow(id, latLng));
    dispatch(scrollToTop());
  };
}

export function setShowUnvoted(val) {
  return {
    type: ActionTypes.SET_SHOW_UNVOTED,
    val
  };
}
