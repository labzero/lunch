import fetch from '../core/fetch';
import ActionTypes from '../constants/ActionTypes';
import { getDecision } from '../selectors/decisions';
import { getNewlyAdded } from '../selectors/listUi';
import { getCurrentUser } from '../selectors/user';
import { processResponse, credentials, jsonHeaders } from '../core/ApiClient';
import { flashError } from './flash.js';

export function sortRestaurants() {
  return (dispatch, getState) => {
    const state = getState();
    return dispatch({
      type: ActionTypes.SORT_RESTAURANTS,
      decision: getDecision(state),
      newlyAdded: getNewlyAdded(state),
      user: getCurrentUser(state)
    });
  };
}

export function invalidateRestaurants() {
  return { type: ActionTypes.INVALIDATE_RESTAURANTS };
}

export function postRestaurant(obj) {
  return {
    type: ActionTypes.POST_RESTAURANT,
    restaurant: obj
  };
}

export function restaurantPosted(obj, userId) {
  return {
    type: ActionTypes.RESTAURANT_POSTED,
    restaurant: obj,
    userId
  };
}

export function deleteRestaurant(teamSlug, id) {
  return {
    type: ActionTypes.DELETE_RESTAURANT,
    id,
    teamSlug
  };
}

export function restaurantDeleted(id, userId) {
  return {
    type: ActionTypes.RESTAURANT_DELETED,
    id,
    userId
  };
}

export function renameRestaurant(teamSlug, id, obj) {
  return {
    type: ActionTypes.RENAME_RESTAURANT,
    id,
    restaurant: obj,
    teamSlug
  };
}

export function restaurantRenamed(id, obj, userId) {
  return {
    type: ActionTypes.RESTAURANT_RENAMED,
    id,
    fields: obj,
    userId
  };
}

export function requestRestaurants(teamSlug) {
  return {
    type: ActionTypes.REQUEST_RESTAURANTS,
    teamSlug
  };
}

export function receiveRestaurants(json, teamSlug) {
  return {
    type: ActionTypes.RECEIVE_RESTAURANTS,
    items: json,
    teamSlug
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

export function voteDeleted(restaurantId, userId, id) {
  return {
    type: ActionTypes.VOTE_DELETED,
    restaurantId,
    userId,
    id
  };
}

export function postNewTagToRestaurant(restaurantId, value) {
  return {
    type: ActionTypes.POST_NEW_TAG_TO_RESTAURANT,
    restaurantId,
    value
  };
}

export function postedNewTagToRestaurant(restaurantId, tag, userId) {
  return {
    type: ActionTypes.POSTED_NEW_TAG_TO_RESTAURANT,
    restaurantId,
    tag,
    userId
  };
}

export function postTagToRestaurant(restaurantId, id) {
  return {
    type: ActionTypes.POST_TAG_TO_RESTAURANT,
    restaurantId,
    id
  };
}

export function postedTagToRestaurant(restaurantId, id, userId) {
  return {
    type: ActionTypes.POSTED_TAG_TO_RESTAURANT,
    restaurantId,
    id,
    userId
  };
}

export function deleteTagFromRestaurant(restaurantId, id, userId) {
  return {
    type: ActionTypes.DELETE_TAG_FROM_RESTAURANT,
    restaurantId,
    id,
    userId
  };
}

export function deletedTagFromRestaurant(restaurantId, id, userId) {
  return {
    type: ActionTypes.DELETED_TAG_FROM_RESTAURANT,
    restaurantId,
    id,
    userId
  };
}

function fetchRestaurants(teamSlug) {
  return dispatch => {
    dispatch(requestRestaurants(teamSlug));
    return fetch(`/api/teams/${teamSlug}/restaurants`, {
      credentials
    })
      .then(response => processResponse(response))
      .then(json => dispatch(receiveRestaurants(json, teamSlug)));
  };
}

function shouldFetchRestaurants(state, teamSlug) {
  const restaurants = state.restaurants;
  if (restaurants.teamSlug !== teamSlug) {
    return true;
  }
  if (!restaurants.items) {
    return true;
  }
  if (restaurants.isFetching) {
    return false;
  }
  return restaurants.didInvalidate;
}

export function fetchRestaurantsIfNeeded(teamSlug) {
  // Note that the function also receives getState()
  // which lets you choose what to dispatch next.

  // This is useful for avoiding a network request if
  // a cached value is already available.

  return (dispatch, getState) => {
    if (shouldFetchRestaurants(getState(), teamSlug)) {
      // Dispatch a thunk from thunk!
      return dispatch(fetchRestaurants(teamSlug));
    }

    // Let the calling code know there's nothing to wait for.
    return Promise.resolve();
  };
}

export function addRestaurant(teamSlug, name, placeId, address, lat, lng) {
  const payload = { name, place_id: placeId, address, lat, lng };
  return (dispatch) => {
    dispatch(postRestaurant(payload));
    return fetch(`/api/teams/${teamSlug}/restaurants`, {
      method: 'post',
      credentials,
      headers: jsonHeaders,
      body: JSON.stringify(payload)
    })
      .then(response => processResponse(response))
      .catch(
        err => dispatch(flashError(err.message))
      );
  };
}

export function removeRestaurant(teamSlug, id) {
  return (dispatch) => {
    dispatch(deleteRestaurant(teamSlug, id));
    return fetch(`/api/teams/${teamSlug}/restaurants/${id}`, {
      credentials,
      method: 'delete'
    });
  };
}

export function changeRestaurantName(teamSlug, id, value) {
  const payload = { name: value };
  return dispatch => {
    dispatch(renameRestaurant(teamSlug, id, payload));
    return fetch(`/api/teams/${teamSlug}/restaurants/${id}`, {
      credentials,
      headers: jsonHeaders,
      method: 'PATCH',
      body: JSON.stringify(payload)
    })
      .then(response => processResponse(response))
      .catch(
        err => dispatch(flashError(err.message))
      );
  };
}

export function addVote(id) {
  return (dispatch) => {
    dispatch(postVote(id));
    return fetch(`/api/restaurants/${id}/votes`, {
      method: 'post',
      credentials
    })
      .then(response => processResponse(response))
      .catch(
        err => dispatch(flashError(err.message))
      );
  };
}

export function removeVote(restaurantId, id) {
  return (dispatch) => {
    dispatch(deleteVote(restaurantId, id));
    return fetch(`/api/restaurants/${restaurantId}/votes/${id}`, {
      credentials,
      method: 'delete'
    });
  };
}

export function addNewTagToRestaurant(restaurantId, value) {
  return (dispatch) => {
    dispatch(postNewTagToRestaurant(restaurantId, value));
    return fetch(`/api/restaurants/${restaurantId}/tags`, {
      method: 'post',
      credentials,
      headers: jsonHeaders,
      body: JSON.stringify({ name: value })
    })
      .then(response => processResponse(response))
      .catch(
        err => dispatch(flashError(err.message))
      );
  };
}

export function addTagToRestaurant(restaurantId, id) {
  return (dispatch) => {
    dispatch(postTagToRestaurant(restaurantId, id));
    return fetch(`/api/restaurants/${restaurantId}/tags`, {
      method: 'post',
      credentials,
      headers: jsonHeaders,
      body: JSON.stringify({ id })
    })
      .then(response => processResponse(response))
      .catch(
        err => dispatch(flashError(err.message))
      );
  };
}

export function removeTagFromRestaurant(restaurantId, id) {
  return (dispatch) => {
    dispatch(deleteTagFromRestaurant(restaurantId, id));
    return fetch(`/api/restaurants/${restaurantId}/tags/${id}`, {
      credentials,
      method: 'delete'
    });
  };
}
