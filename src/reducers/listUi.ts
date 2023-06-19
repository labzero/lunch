import { createNextState } from "@reduxjs/toolkit";
import { Reducer } from "../interfaces";

const listUi: Reducer<"listUi"> = (state, action) =>
  createNextState(state, (draftState) => {
    switch (action.type) {
      case "RESTAURANT_RENAMED":
      case "RESTAURANT_DELETED": {
        draftState[action.id] = {};
        return;
      }
      case "RESTAURANT_POSTED": {
        draftState.newlyAdded = {
          id: action.restaurant.id,
          userId: action.userId,
        };
        draftState[action.restaurant.id] = {};
        return;
      }
      case "SET_EDIT_NAME_FORM_VALUE": {
        draftState[action.id] = {
          ...draftState[action.id],
          editNameFormValue: action.value,
        };
        return;
      }
      case "SHOW_EDIT_NAME_FORM": {
        draftState[action.id] = {
          ...draftState[action.id],
          isEditingName: true,
        };
        return;
      }
      case "HIDE_EDIT_NAME_FORM": {
        draftState[action.id] = {
          ...draftState[action.id],
          isEditingName: false,
        };
        return;
      }
      case "SET_FLIP_MOVE": {
        draftState.flipMove = action.val;
        break;
      }
      default:
        break;
    }
  });

export default listUi;
