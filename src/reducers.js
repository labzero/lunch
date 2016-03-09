import * as ActionTypes from './ActionTypes';

const initialState = {
  restaurants: {
    isFetching: false,
    didInvalidate: false,
    items: []
  },
  flashes: [],
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
      isFetching: false,
      items: state.items.filter(item => item.id !== action.key)
    });
  },
  [ActionTypes.POST_VOTE](state) {
    return Object.assign({}, state, {
      isFetching: true
    });
  },
  [ActionTypes.VOTE_POSTED](state, action) {
    return Object.assign({}, state, {
      isFetching: false,
      items: state.items.map(item => {
        if (item.id === action.vote.restaurant_id) {
          const newItem = Object.assign({}, item);
          newItem.votes = [
            ...item.votes,
            action.vote
          ];
          return newItem;
        }
        return item;
      })
    });
  },
  [ActionTypes.DELETE_VOTE](state) {
    return Object.assign({}, state, {
      isFetching: true
    });
  },
  [ActionTypes.VOTE_DELETED](state, action) {
    return Object.assign({}, state, {
      isFetching: false,
      items: state.items.map(item => {
        if (item.id === action.restaurantId) {
          const newItem = Object.assign({}, item);
          newItem.votes = item.votes.filter(
            vote => vote.id !== action.id
          );
          return newItem;
        }
        return item;
      })
    });
  }
};

const flashesMap = {
  [ActionTypes.FLASH_ERROR](state, action) {
    return [
      ...state,
      {
        message: action.message,
        type: 'error'
      }
    ];
  },
  [ActionTypes.EXPIRE_FLASH](state, action) {
    const newState = Array.from(state);
    newState.splice(action.id, 1);
    return newState;
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
export const flashes = generateReducer(flashesMap, initialState.flashes);
export const user = generateReducer({}, initialState.user);
export const latLng = generateReducer({}, initialState.latLng);
