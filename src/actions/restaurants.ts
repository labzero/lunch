import { getDecision } from '../selectors/decisions';
import { getNewlyAdded } from '../selectors/listUi';
import { getCurrentUser } from '../selectors/user';
import { processResponse, credentials, jsonHeaders } from '../core/ApiClient';
import { ThunkAction } from '@reduxjs/toolkit';
import { Action, Restaurant, State, Tag, Vote } from '../interfaces';

export function sortRestaurants(): ThunkAction<void, State, unknown, Action> {
  return (dispatch, getState) => {
    const state = getState();
    return dispatch({
      type: "SORT_RESTAURANTS",
      decision: getDecision(state),
      newlyAdded: getNewlyAdded(state),
      user: getCurrentUser(state)
    });
  };
}

export function invalidateRestaurants(): Action {
  return { type: "INVALIDATE_RESTAURANTS" };
}

export function postRestaurant(obj: Partial<Restaurant>): Action {
  return {
    type: "POST_RESTAURANT",
    restaurant: obj
  };
}

export function restaurantPosted(obj: Restaurant, userId: number): Action {
  return {
    type: "RESTAURANT_POSTED",
    restaurant: obj,
    userId
  };
}

export function deleteRestaurant(id: number): Action {
  return {
    type: "DELETE_RESTAURANT",
    id
  };
}

export function restaurantDeleted(id: number, userId: number): Action {
  return {
    type: "RESTAURANT_DELETED",
    id,
    userId
  };
}

export function renameRestaurant(id: number, obj: Partial<Restaurant>): Action {
  return {
    type: "RENAME_RESTAURANT",
    id,
    restaurant: obj
  };
}

export function restaurantRenamed(id: number, obj: Restaurant, userId: number): Action {
  return {
    type: "RESTAURANT_RENAMED",
    id,
    fields: obj,
    userId
  };
}

export function requestRestaurants(): Action {
  return {
    type: "REQUEST_RESTAURANTS"
  };
}

export function receiveRestaurants(json: Restaurant[]): Action {
  return {
    type: "RECEIVE_RESTAURANTS",
    items: json
  };
}

export function postVote(id: number): Action {
  return {
    type: "POST_VOTE",
    id
  };
}

export function votePosted(json: Vote): Action {
  return {
    type: "VOTE_POSTED",
    vote: json
  };
}

export function deleteVote(restaurantId: number, id: number): Action {
  return {
    type: "DELETE_VOTE",
    restaurantId,
    id
  };
}

export function voteDeleted(restaurantId: number, userId: number, id: number): Action {
  return {
    type: "VOTE_DELETED",
    restaurantId,
    userId,
    id
  };
}

export function postNewTagToRestaurant(restaurantId: number, value: string): Action {
  return {
    type: "POST_NEW_TAG_TO_RESTAURANT",
    restaurantId,
    value
  };
}

export function postedNewTagToRestaurant(restaurantId: number, tag: Tag, userId: number): Action {
  return {
    type: "POSTED_NEW_TAG_TO_RESTAURANT",
    restaurantId,
    tag,
    userId
  };
}

export function postTagToRestaurant(restaurantId: number, id: number): Action {
  return {
    type: "POST_TAG_TO_RESTAURANT",
    restaurantId,
    id
  };
}

export function postedTagToRestaurant(restaurantId: number, id: number, userId: number): Action {
  return {
    type: "POSTED_TAG_TO_RESTAURANT",
    restaurantId,
    id,
    userId
  };
}

export function deleteTagFromRestaurant(restaurantId: number, id: number): Action {
  return {
    type: "DELETE_TAG_FROM_RESTAURANT",
    restaurantId,
    id
  };
}

export function deletedTagFromRestaurant(restaurantId: number, id: number, userId: number): Action {
  return {
    type: "DELETED_TAG_FROM_RESTAURANT",
    restaurantId,
    id,
    userId
  };
}

export function setNameFilter(val: string): Action {
  return {
    type: "SET_NAME_FILTER",
    val,
  };
}

export function fetchRestaurants(): ThunkAction<void, State, unknown, Action> {
  return dispatch => {
    dispatch(requestRestaurants());
    return fetch('/api/restaurants', {
      credentials,
      headers: jsonHeaders
    })
      .then(response => processResponse(response, dispatch))
      .then(json => dispatch(receiveRestaurants(json)));
  };
}

function shouldFetchRestaurants(state: State) {
  const restaurants = state.restaurants;
  if (!restaurants.items) {
    return true;
  }
  if (restaurants.isFetching) {
    return false;
  }
  return restaurants.didInvalidate;
}

export function fetchRestaurantsIfNeeded(): ThunkAction<void, State, unknown, Action> {
  // Note that the function also receives getState()
  // which lets you choose what to dispatch next.

  // This is useful for avoiding a network request if
  // a cached value is already available.

  return (dispatch, getState) => {
    if (shouldFetchRestaurants(getState())) {
      // Dispatch a thunk from thunk!
      return dispatch(fetchRestaurants());
    }

    // Let the calling code know there's nothing to wait for.
    return Promise.resolve();
  };
}

export function addRestaurant(name: string, placeId: string, address: string, lat: number, lng: number): ThunkAction<void, State, unknown, Action> {
  const payload: Partial<Restaurant> = {
    name, placeId, address, lat, lng
  };
  return (dispatch) => {
    dispatch(postRestaurant(payload));
    return fetch('/api/restaurants', {
      method: 'post',
      credentials,
      headers: jsonHeaders,
      body: JSON.stringify(payload)
    })
      .then(response => processResponse(response, dispatch));
  };
}

export function removeRestaurant(id: number): ThunkAction<void, State, unknown, Action> {
  return (dispatch) => {
    dispatch(deleteRestaurant(id));
    return fetch(`/api/restaurants/${id}`, {
      credentials,
      method: 'delete'
    })
      .then(response => processResponse(response, dispatch));
  };
}

export function changeRestaurantName(id: number, name: string): ThunkAction<void, State, unknown, Action> {
  const payload: Partial<Restaurant> = { name };
  return dispatch => {
    dispatch(renameRestaurant(id, payload));
    return fetch(`/api/restaurants/${id}`, {
      credentials,
      headers: jsonHeaders,
      method: 'PATCH',
      body: JSON.stringify(payload)
    })
      .then(response => processResponse(response, dispatch));
  };
}

export function addVote(id: number): ThunkAction<void, State, unknown, Action> {
  return (dispatch) => {
    dispatch(postVote(id));
    return fetch(`/api/restaurants/${id}/votes`, {
      method: 'post',
      credentials
    })
      .then(response => processResponse(response, dispatch));
  };
}

export function removeVote(restaurantId: number, id: number): ThunkAction<void, State, unknown, Action> {
  return (dispatch) => {
    dispatch(deleteVote(restaurantId, id));
    return fetch(`/api/restaurants/${restaurantId}/votes/${id}`, {
      credentials,
      method: 'delete'
    })
      .then(response => processResponse(response, dispatch));
  };
}

export function addNewTagToRestaurant(restaurantId: number, name: string): ThunkAction<void, State, unknown, Action> {
  return (dispatch) => {
    dispatch(postNewTagToRestaurant(restaurantId, name));
    return fetch(`/api/restaurants/${restaurantId}/tags`, {
      method: 'post',
      credentials,
      headers: jsonHeaders,
      body: JSON.stringify({ name })
    })
      .then(response => processResponse(response, dispatch));
  };
}

export function addTagToRestaurant(restaurantId: number, id: number): ThunkAction<void, State, unknown, Action> {
  return (dispatch) => {
    dispatch(postTagToRestaurant(restaurantId, id));
    return fetch(`/api/restaurants/${restaurantId}/tags`, {
      method: 'post',
      credentials,
      headers: jsonHeaders,
      body: JSON.stringify({ id })
    })
      .then(response => processResponse(response, dispatch));
  };
}

export function removeTagFromRestaurant(restaurantId: number, id: number): ThunkAction<void, State, unknown, Action> {
  return (dispatch) => {
    dispatch(deleteTagFromRestaurant(restaurantId, id));
    return fetch(`/api/restaurants/${restaurantId}/tags/${id}`, {
      credentials,
      method: 'delete'
    })
      .then(response => processResponse(response, dispatch));
  };
}
