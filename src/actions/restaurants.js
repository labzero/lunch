import fetch from '../core/fetch';
import * as ActionTypes from '../ActionTypes';
import ApiClient from '../core/ApiClient';
import { flashError } from './flash.js';

export function invalidateRestaurants() {
  return { type: ActionTypes.INVALIDATE_RESTAURANTS };
}

export function postRestaurant(obj) {
  return {
    type: ActionTypes.POST_RESTAURANT,
    restaurant: obj
  };
}

export function restaurantPosted(obj) {
  return {
    type: ActionTypes.RESTAURANT_POSTED,
    restaurant: obj
  };
}

export function deleteRestaurant(key) {
  return {
    type: ActionTypes.DELETE_RESTAURANT,
    key
  };
}

export function restaurantDeleted(key) {
  return {
    type: ActionTypes.RESTAURANT_DELETED,
    key
  };
}

export function requestRestaurants() {
  return { type: ActionTypes.REQUEST_RESTAURANTS };
}

export function receiveRestaurants(json) {
  return {
    type: ActionTypes.RECEIVE_RESTAURANTS,
    items: json
  };
}

export function postVote(id) {
  return {
    type: ActionTypes.POST_VOTE,
    id
  };
}

export function votePosted(json) {
  return {
    type: ActionTypes.VOTE_POSTED,
    vote: json
  };
}

export function deleteVote(restaurantId, id) {
  return {
    type: ActionTypes.DELETE_VOTE,
    restaurantId,
    id
  };
}

export function voteDeleted(restaurantId, id) {
  return {
    type: ActionTypes.VOTE_DELETED,
    restaurantId,
    id
  };
}

export function showInfoWindow(id) {
  return {
    type: ActionTypes.SHOW_INFO_WINDOW,
    id
  };
}

export function hideInfoWindow(id) {
  return {
    type: ActionTypes.HIDE_INFO_WINDOW,
    id
  };
}

function fetchRestaurants() {
  return dispatch => {
    dispatch(requestRestaurants());
    return fetch('/api/restaurants')
      .then(response => new ApiClient(response).processResponse())
      .then(json => dispatch(receiveRestaurants(json)));
  };
}

function shouldFetchRestaurants(state) {
  const items = state.restaurants.items;
  if (!items) {
    return true;
  }
  if (items.isFetching) {
    return false;
  }
  return items.didInvalidate;
}

export function fetchRestaurantsIfNeeded() {
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

export function addRestaurant(name, placeId, address, lat, lng) {
  return (dispatch) => {
    dispatch(postRestaurant());
    return fetch('/api/restaurants', {
      method: 'post',
      credentials: 'same-origin',
      headers: {
        Accept: 'application/json',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ name, place_id: placeId, address, lat, lng })
    })
      .then(response => new ApiClient(response).processResponse())
      .then(
        json => dispatch(restaurantPosted(json)),
        err => dispatch(flashError(err.message))
      );
  };
}

export function removeRestaurant(key) {
  return (dispatch) => {
    dispatch(deleteRestaurant(key));
    return fetch(`/api/restaurants/${key}`, {
      credentials: 'same-origin',
      method: 'delete'
    }).then(() => dispatch(restaurantDeleted(key)));
  };
}

export function addVote(id) {
  return (dispatch) => {
    dispatch(postVote(id));
    return fetch(`/api/restaurants/${id}/votes`, {
      method: 'post',
      credentials: 'same-origin'
    })
      .then(response => new ApiClient(response).processResponse())
      .then(
        json => dispatch(votePosted(json)),
        err => dispatch(flashError(err.message))
      );
  };
}

export function removeVote(restaurantId, id) {
  return (dispatch) => {
    dispatch(deleteVote(restaurantId, id));
    return fetch(`/api/restaurants/${restaurantId}/votes/${id}`, {
      credentials: 'same-origin',
      method: 'delete'
    })
      .then(() => dispatch(voteDeleted(restaurantId, id)));
  };
}
