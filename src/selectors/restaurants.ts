import { createSelector, Selector } from "reselect";
import { Restaurant, State } from "../interfaces";

type PartialState = Partial<State> & Pick<State, "restaurants">;

export const areRestaurantsLoading: Selector<PartialState, boolean> = (state) =>
  state.restaurants.didInvalidate;
export const getRestaurantId: Selector<PartialState, number> = (
  state,
  props: number | { restaurantId: number }
) => (typeof props === "number" ? props : props.restaurantId);
export const getRestaurantIds: Selector<PartialState, number[]> = (state) =>
  state.restaurants.items.result;
export const getRestaurantEntities: Selector<
  PartialState,
  { [index: number]: Restaurant }
> = (state) => state.restaurants.items.entities.restaurants;

export const getRestaurantById = createSelector(
  getRestaurantEntities,
  getRestaurantId,
  (restaurantEntities, id) => restaurantEntities[id]
);

export const getRestaurants = createSelector(
  getRestaurantIds,
  getRestaurantEntities,
  (restaurantIds, restaurantEntities) =>
    restaurantIds.map((id) => restaurantEntities[id])
);

export const getTagsForRestaurant = createSelector(
  getRestaurantById,
  (restaurant) => restaurant.tags
);

export const getNameFilter: Selector<PartialState, string> = (state) =>
  state.restaurants.nameFilter;
