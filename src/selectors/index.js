import { getRestaurantIds, getRestaurantsEntities } from './restaurants';
import { getMapUi } from './mapUi';
import { createSelector } from 'reselect';

export const getAllOrUnvoted = createSelector(
  [getRestaurantIds, getRestaurantsEntities, getMapUi],
  (restaurantIds, restaurantsEntities, mapUi) => restaurantIds.filter(id =>
    mapUi.showUnvoted || (!mapUi.showUnvoted && restaurantsEntities[id].votes.length > 0)
  )
);
