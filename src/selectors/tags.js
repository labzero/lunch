import { createSelector } from 'reselect';

const emptyObj = {};

export const areTagsLoading = state => state.tags.didInvalidate;
export const getTagIds = state => state.tags.items.result;
export const getTagEntities = state => state.tags.items.entities.tags || emptyObj;

export const getTags = createSelector(
  [getTagIds, getTagEntities],
  (tagIds, tagEntities) => tagIds.map(id => tagEntities[id])
);

export const getTagById = (state, props) => getTagEntities(state)[typeof props === 'object' ? props.tagId : props];
