import { Reducer } from "../interfaces";

const tagExclusions: Reducer<"tagExclusions"> = (state, action) => {
  switch (action.type) {
    case "ADD_TAG_EXCLUSION": {
      return [...state, action.id];
    }
    case "REMOVE_TAG_EXCLUSION": {
      return state.filter((t) => t !== action.id);
    }
    case "CLEAR_TAG_EXCLUSIONS": {
      return [];
    }
    default:
      break;
  }
  return state;
};

export default tagExclusions;
