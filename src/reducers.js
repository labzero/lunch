import * as ActionTypes from './ActionTypes';

const initialState = {
  isFetching: false,
  didInvalidate: false,
  items: []
};

const restaurantsMap = {
  [ActionTypes.INVALIDATE_RESTAURANTS](state) {
    return Object.assign({}, state, {
      didInvalidate: true
    });
  },
  [ActionTypes.REQUEST_RESTAURANTS](state) {
    return Object.assign({}, state, {
      isFetching: true,
      didInvalidate: false
    });
  },
  [ActionTypes.RECEIVE_RESTAURANTS](state, action) {
    return Object.assign({}, state, {
      isFetching: false,
      didInvalidate: false,
      items: action.items
    });
  },
  [ActionTypes.POST_RESTAURANT](state) {
    return Object.assign({}, state, {
      isFetching: true
    });
  },
  [ActionTypes.RESTAURANT_POSTED](state, action) {
    return Object.assign({}, state, {
      isFetching: false,
      items: [
        ...state.items,
        action.restaurant
      ]
    });
  },
  [ActionTypes.DELETE_RESTAURANT](state) {
    return Object.assign({}, state, {
      isFetching: true
    });
  },
  [ActionTypes.RESTAURANT_DELETED](state, action) {
    return Object.assign({}, state, {
      items: state.items.filter(item => item.id !== action.key)
    });
  }
};

export function restaurants(state = initialState, action) {
  const reducer = restaurantsMap[action.type];
  if (reducer === undefined) {
    return state;
  }
  return reducer(state, action);
}
