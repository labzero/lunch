import { createNextState } from "@reduxjs/toolkit";
import { Reducer } from "../interfaces";

const pageUi: Reducer<"pageUi"> = (state, action) =>
  createNextState(state, (draftState) => {
    switch (action.type) {
      case "SCROLL_TO_TOP": {
        draftState.shouldScrollToTop = true;
        return;
      }
      case "SCROLLED_TO_TOP": {
        draftState.shouldScrollToTop = false;
        break;
      }
      default:
        break;
    }
  });

export default pageUi;
