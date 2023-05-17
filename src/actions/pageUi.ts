import { Action } from "../interfaces";

export function scrollToTop(): Action {
  return {
    type: "SCROLL_TO_TOP",
  };
}

export function scrolledToTop(): Action {
  return {
    type: "SCROLLED_TO_TOP",
  };
}
