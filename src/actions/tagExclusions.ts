import { Action } from "../interfaces";

export function addTagExclusion(id: number): Action {
  return {
    type: "ADD_TAG_EXCLUSION",
    id
  };
}

export function clearTagExclusions(): Action {
  return { type: "CLEAR_TAG_EXCLUSIONS" };
}

export function removeTagExclusion(id: number): Action {
  return {
    type: "REMOVE_TAG_EXCLUSION",
    id
  };
}
