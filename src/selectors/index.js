import { getRestaurantIds, getRestaurantEntities, getRestaurantById } from './restaurants';
import { getVoteEntities, getVoteById } from './votes';
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

export const getAllOrUnvoted = createSelector(
  [getRestaurantIds, getRestaurantEntities, getMapUi],
  (restaurantIds, restaurantEntities, mapUi) => restaurantIds.filter(id =>
    mapUi.showUnvoted || (!mapUi.showUnvoted && restaurantEntities[id].votes.length > 0)
  )
);
