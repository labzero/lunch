import * as ActionTypes from './ActionTypes';

const initialState = {
  restaurants: {
    isFetching: false,
    didInvalidate: false,
    items: []
  },
  flash: {},
  user: {},
  latLng: {}
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

const flashMap = {
  [ActionTypes.FLASH_ERROR](state, action) {
    return Object.assign({}, state, {
      flash: {
        error: action.message
      }
    });
  }
};

const generateReducer = (map, initial) => (state = initial, action) => {
  const reducer = map[action.type];
  if (reducer === undefined) {
    return state;
  }
  return reducer(state, action);
};

export const restaurants = generateReducer(restaurantsMap, initialState.restaurants);
export const flash = generateReducer(flashMap, initialState.flash);
export const user = generateReducer({}, initialState.user);
export const latLng = generateReducer({}, initialState.latLng);
