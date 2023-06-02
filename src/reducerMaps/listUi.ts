import update from "immutability-helper";
import setOrMerge from "./helpers/setOrMerge";
import { Reducer } from "../interfaces";

const listUi: Reducer<"listUi"> = (state, action) => {
  switch (action.type) {
    case "RESTAURANT_RENAMED":
    case "RESTAURANT_DELETED": {
      return update(state, {
        $merge: {
          [action.id]: {},
        },
      });
    }
    case "RESTAURANT_POSTED": {
      return update(state, {
        newlyAdded: {
          $set: {
            id: action.restaurant.id,
            userId: action.userId,
          },
        },
        $merge: {
          [action.restaurant.id]: {},
        },
      });
    }
    case "SET_EDIT_NAME_FORM_VALUE": {
      return update(state, {
        $apply: (target: typeof state) =>
          setOrMerge(target, action.id, { editNameFormValue: action.value }),
      });
    }
    case "SHOW_EDIT_NAME_FORM": {
      return update(state, {
        $apply: (target: typeof state) =>
          setOrMerge(target, action.id, { isEditingName: true }),
      });
    }
    case "HIDE_EDIT_NAME_FORM": {
      return update(state, {
        $apply: (target: typeof state) =>
          setOrMerge(target, action.id, { isEditingName: false }),
      });
    }
    case "SET_FLIP_MOVE": {
      return update(state, {
        flipMove: {
          $set: action.val,
        },
      });
    }
    default:
      break;
  }
  return state;
};

export default listUi;
