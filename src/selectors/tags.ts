import { createSelector } from "reselect";
import { State } from "../interfaces";

const emptyObj = {};

export const areTagsLoading = (state: State) => state.tags.didInvalidate;
export const getTagIds = (state: Partial<State> & Pick<State, "tags">) =>
  state.tags.items.result;
export const getTagEntities = (state: Partial<State> & Pick<State, "tags">) =>
  state.tags.items.entities.tags || emptyObj;

export const getTags = createSelector(
  getTagIds,
  getTagEntities,
  (tagIds, tagEntities) => tagIds.map((id) => tagEntities[id])
);

export const getTagById = (
  state: Partial<State> & Pick<State, "tags">,
  props: { tagId: number } | number
) => getTagEntities(state)[typeof props === "object" ? props.tagId : props];
