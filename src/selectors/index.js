import { getRestaurantIds, getRestaurantEntities, getRestaurantById } from './restaurants';
import { getVoteEntities, getVoteById } from './votes';
import { getTags } from './tags';
import { getTagFilters } from './tagFilters';
import { getTagExclusions } from './tagExclusions';
import { getUserId, getUserById } from './users';
import { getMapUi } from './mapUi';
import { getDecision } from './decisions';
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
  [getRestaurantIds, getTagFilters, getTagExclusions, getRestaurantEntities],
  (restaurantIds, tagFilters, tagExclusions, restaurantEntities) => {
    if (tagFilters.length === 0 && tagExclusions.length === 0) { return restaurantIds; }
    return restaurantIds.filter(id =>
      (tagFilters.length === 0 || tagFilters.every(tagFilter =>
        restaurantEntities[id].tags.includes(tagFilter))) &&
      (tagExclusions.length === 0 || tagExclusions.every(tagExclusion =>
        !restaurantEntities[id].tags.includes(tagExclusion)))
    );
  }
);

export const makeGetAllDecisionCountForRestaurant = () =>
  createSelector(
    [getRestaurantById, getDecision],
    (restaurant, decision) => {
      let currentDecisionCount = parseInt(restaurant.all_decision_count, 10);
      if (decision.restaurant_id === restaurant.id) {
        currentDecisionCount += 1;
      } 
      return currentDecisionCount;
    }
  );
