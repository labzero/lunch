import * as ActionTypes from './ActionTypes';

export const restaurants = {
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
        action.restaurant,
        ...state.items
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
  },
  [ActionTypes.SHOW_INFO_WINDOW](state, action) {
    return Object.assign({}, state, {
      items: state.items.map(item => {
        if (item.id === action.id) {
          return Object.assign({}, item, { showInfoWindow: true });
        }
        return item;
      })
    });
  },
  [ActionTypes.HIDE_INFO_WINDOW](state, action) {
    return Object.assign({}, state, {
      items: state.items.map(item => {
        if (item.id === action.id) {
          return Object.assign({}, item, { showInfoWindow: false });
        }
        return item;
      })
    });
  },
  [ActionTypes.SHOW_ADD_TAG_FORM](state, action) {
    return Object.assign({}, state, {
      items: state.items.map(item => {
        if (item.id === action.id) {
          return Object.assign({}, item, { isAddingTags: true });
        }
        return item;
      })
    });
  },
  [ActionTypes.HIDE_ADD_TAG_FORM](state, action) {
    return Object.assign({}, state, {
      items: state.items.map(item => {
        if (item.id === action.id) {
          return Object.assign({}, item, { isAddingTags: false });
        }
        return item;
      })
    });
  }
};

export const tags = {};

export const flashes = {
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

export const user = {};

export const latLng = {};
