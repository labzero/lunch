import { Reducer } from "../interfaces";

const tagFilters: Reducer<"tagFilters"> = (state, action) => {
  switch (action.type) {
    case "ADD_TAG_FILTER": {
      return [...state, action.id];
    }
    case "REMOVE_TAG_FILTER": {
      return state.filter((t) => t !== action.id);
    }
    case "CLEAR_TAG_FILTERS": {
      return [];
    }
    default:
      break;
  }
  return state;
};

export default tagFilters;
