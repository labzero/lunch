import { Action } from "../interfaces";

export function addTagFilter(id: number): Action {
  return {
    type: "ADD_TAG_FILTER",
    id
  };
}

export function clearTagFilters(): Action {
  return { type: "CLEAR_TAG_FILTERS" };
}

export function removeTagFilter(id: number): Action {
  return {
    type: "REMOVE_TAG_FILTER",
    id
  };
}
