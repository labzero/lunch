import update from "immutability-helper";
import { Reducer } from "../interfaces";

const pageUi: Reducer<"pageUi"> = (state, action) => {
  switch (action.type) {
    case "SCROLL_TO_TOP": {
      return update(state, {
        $merge: {
          shouldScrollToTop: true,
        },
      });
    }
    case "SCROLLED_TO_TOP": {
      return update(state, {
        $merge: {
          shouldScrollToTop: false,
        },
      });
    }
  }
  return state;
};

export default pageUi;
