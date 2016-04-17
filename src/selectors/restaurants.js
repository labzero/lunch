import { createSelector } from 'reselect';

export const getRestaurantIds = state => state.restaurants.items.result;
export const getRestaurantEntities = state => state.restaurants.items.entities.restaurants;
export const getRestaurantById = (state, props) =>
  getRestaurantEntities(state)[typeof props === 'object' ? props.restaurantId : props];

export const getRestaurants = createSelector(
  [getRestaurantIds, getRestaurantEntities],
  (restaurantIds, restaurantEntities) => restaurantIds.map(id => restaurantEntities[id])
);
