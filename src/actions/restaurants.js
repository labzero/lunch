import fetch from '../core/fetch';

export const INVALIDATE_RESTAURANTS = 'INVALIDATE_RESTAURANTS';
export function invalidateRestaurants() {
  return { type: INVALIDATE_RESTAURANTS };
}

export const REQUEST_RESTAURANTS = 'REQUEST_RESTAURANTS';
export function requestRestaurants() {
  return { type: REQUEST_RESTAURANTS };
}

export const RECEIVE_RESTAURANTS = 'RECEIVE_RESTAURANTS';
export function receiveRestaurants(json) {
  return {
    type: RECEIVE_RESTAURANTS,
    items: json
  };
}

function fetchRestaurants() {
  return dispatch => {
    dispatch(requestRestaurants());
    return fetch('/api/restaurants')
      .then(response => response.json())
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

export default function fetchRestaurantsIfNeeded() {
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
