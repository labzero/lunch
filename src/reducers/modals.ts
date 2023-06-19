import { createNextState } from "@reduxjs/toolkit";
import { Reducer } from "../interfaces";

const modals: Reducer<"modals"> = (state, action) =>
  createNextState(state, (draftState) => {
    switch (action.type) {
      case "SHOW_MODAL": {
        draftState[action.name] = {
          shown: true,
          ...("opts" in action ? action.opts : undefined),
        };
        return;
      }
      case "HIDE_MODAL": {
        draftState[action.name] = {
          ...draftState[action.name],
          shown: false,
        };
        break;
      }
      default:
        break;
    }
  });

export default modals;
