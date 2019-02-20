import { createSelector } from 'reselect';
import hasRole from '../helpers/hasRole';
import { areDecisionsLoading } from './decisions';
import {
  areRestaurantsLoading,
  getNameFilter,
  getRestaurantIds,
  getRestaurantEntities,
  getRestaurantById
} from './restaurants';
import { getVoteEntities, getVoteById } from './votes';
import { getTeam } from './team';
import { areTagsLoading } from './tags';
import { getTagFilters } from './tagFilters';
import { getTagExclusions } from './tagExclusions';
import { areUsersLoading, getUserId, getUserById } from './users';
import { getCurrentUser } from './user';
import { getMapUi } from './mapUi';

export const getUserByVoteId = (state, voteId) => getUserById(state, getVoteById(state, voteId).user_id);

export const makeGetRestaurantVotesForUser = () => createSelector(
  getRestaurantById, getVoteEntities, getUserId,
  (restaurant, voteEntities, userId) => restaurant.votes.filter(voteId => voteEntities[voteId].user_id === userId)
);

export const getMapItems = createSelector(
  getRestaurantIds, getRestaurantEntities, getMapUi,
  (restaurantIds, restaurantEntities, mapUi) => restaurantIds.filter(id => mapUi.showUnvoted || (!mapUi.showUnvoted && restaurantEntities[id].votes.length > 0)).map(id => ({ id, lat: restaurantEntities[id].lat, lng: restaurantEntities[id].lng }))
);

export const getFilteredRestaurants = createSelector(
  getRestaurantIds, getNameFilter, getTagFilters, getTagExclusions, getRestaurantEntities,
  (restaurantIds, nameFilter, tagFilters, tagExclusions, restaurantEntities) => {
    if (
      tagFilters.length === 0
      && tagExclusions.length === 0
      && nameFilter.length === 0
    ) { return restaurantIds; }
    return restaurantIds.filter(id => (tagFilters.length === 0 || tagFilters.every(tagFilter => restaurantEntities[id].tags.includes(tagFilter)))
      && (tagExclusions.length === 0 || tagExclusions.every(tagExclusion => !restaurantEntities[id].tags.includes(tagExclusion)))
      && restaurantEntities[id].name.toLowerCase().indexOf(nameFilter.toLowerCase()) > -1);
  }
);

const getRoleProp = (state, props) => props.role || props;
export const currentUserHasRole = createSelector(
  getCurrentUser, getTeam, getRoleProp,
  hasRole
);

export const isRestaurantListReady = createSelector(
  areRestaurantsLoading, areTagsLoading, areUsersLoading, areDecisionsLoading,
  (restaurantsLoading, tagsLoading, usersLoading, decisionsLoading) => !restaurantsLoading && !tagsLoading && !usersLoading && !decisionsLoading
);

export const isUserListReady = createSelector(
  areUsersLoading,
  (usersLoading) => !usersLoading
);

export const isTagListReady = createSelector(
  areTagsLoading,
  (tagsLoading) => !tagsLoading
);
