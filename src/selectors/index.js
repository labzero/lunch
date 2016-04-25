import { getRestaurantIds, getRestaurantEntities, getRestaurantById } from './restaurants';
import { getVoteEntities, getVoteById } from './votes';
import { getTags } from './tags';
import { getTagFilters } from './tagFilters';
import { getUserId, getUserById } from './users';
import { getMapUi } from './mapUi';
import { createSelector } from 'reselect';

export const getUserByVoteId = (state, voteId) => getUserById(state, getVoteById(state, voteId).user_id);

export const makeGetRestaurantVotesForUser = () =>
  createSelector(
    [getRestaurantById, getVoteEntities, getUserId],
    (restaurant, voteEntities, userId) =>
      restaurant.votes.filter(voteId => voteEntities[voteId].user_id === userId)
  );

const getAddedTags = (state, props) => props.addedTags;
const getAutosuggestValue = (state, props) => props.autosuggestValue;
const escapeRegexCharacters = (str) => str.replace(/[.*+?^${}()|[\]\\]/gi, '\\$&');

export const makeGetTagList = () =>
  createSelector(
    [getTags, getAddedTags, getAutosuggestValue],
    (allTags, addedTags, autosuggestValue) => {
      const escapedValue = escapeRegexCharacters(autosuggestValue.trim());
      const regex = new RegExp(`${escapedValue}`, 'i');
      return allTags
        .filter(tag => addedTags.indexOf(tag.id) === -1)
        .filter(tag => regex.test(tag.name))
        .slice(0, 10);
    }
  );

export const getMapItems = createSelector(
  [getRestaurantIds, getRestaurantEntities, getMapUi],
  (restaurantIds, restaurantEntities, mapUi) => restaurantIds.filter(id =>
    mapUi.showUnvoted || (!mapUi.showUnvoted && restaurantEntities[id].votes.length > 0)
  ).map(id => ({ id, lat: restaurantEntities[id].lat, lng: restaurantEntities[id].lng }))
);

export const getFilteredRestaurants = createSelector(
  [getRestaurantIds, getTagFilters, getRestaurantEntities],
  (restaurantIds, tagFilters, restaurantEntities) => {
    if (tagFilters.length === 0) { return restaurantIds; }
    return restaurantIds.filter(id =>
      tagFilters.every(tagFilter =>
        restaurantEntities[id].tags.includes(tagFilter)
      )
    );
  }
);
