export const getRestaurantIds = state => state.restaurants.items.result;
export const getRestaurantsEntities = state => state.restaurants.items.entities.restaurants;
export const getRestaurantById = (state, id) => getRestaurantsEntities(state)[id];
