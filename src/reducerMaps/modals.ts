import update from "immutability-helper";
import { Reducer } from "../interfaces";

const modals: Reducer<"modals"> = (state, action) => {
  switch (action.type) {
    case "SHOW_MODAL": {
      return update(state, {
        $merge: {
          [action.name]: {
            shown: true,
            ...action.opts,
          },
        },
      });
    }
    case "HIDE_MODAL": {
      return update(state, {
        [action.name]: (stateValue) =>
          update(stateValue || {}, { $merge: { shown: false } }),
      });
    }
    default:
      break;
  }
  return state;
};

export default modals;
