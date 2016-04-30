import { createSelector } from 'reselect';

export const getRestaurantId = (state, props) => typeof props === 'object' ? props.restaurantId : props;
export const getRestaurantIds = state => state.restaurants.items.result;
export const getRestaurantEntities = state => state.restaurants.items.entities.restaurants;

export const getRestaurantById = createSelector(
  [getRestaurantEntities, getRestaurantId],
  (restaurantEntities, id) => restaurantEntities[id]
);

export const getRestaurants = createSelector(
  [getRestaurantIds, getRestaurantEntities],
  (restaurantIds, restaurantEntities) => restaurantIds.map(id => restaurantEntities[id])
);

export const getTagsForRestaurant = createSelector(
  [getRestaurantById],
  (restaurant) => restaurant.tags
);
