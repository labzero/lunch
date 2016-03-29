import ActionTypes from '../constants/ActionTypes';

export function scrollToTop() {
  return {
    type: ActionTypes.SCROLL_TO_TOP
  };
}

export function scrolledToTop() {
  return {
    type: ActionTypes.SCROLLED_TO_TOP
  };
}
