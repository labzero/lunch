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

export function createTempMarker(result) {
  return {
    type: ActionTypes.CREATE_TEMP_MARKER,
    result
  };
}

export function clearTempMarker() {
  return {
    type: ActionTypes.CLEAR_TEMP_MARKER
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
