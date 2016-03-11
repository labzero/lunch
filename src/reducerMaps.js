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
      items: state.items.filter(item => item.id !== action.id)
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
          return Object.assign({}, item, {
            votes: [
              ...item.votes,
              action.vote
            ]
          });
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
          return Object.assign({}, item, {
            votes: item.votes.filter(
              vote => vote.id !== action.id
            )
          });
        }
        return item;
      })
    });
  },
  [ActionTypes.POST_NEW_TAG_TO_RESTAURANT](state) {
    return Object.assign({}, state, {
      isFetching: true
    });
  },
  [ActionTypes.POSTED_NEW_TAG_TO_RESTAURANT](state, action) {
    return Object.assign({}, state, {
      isFetching: false,
      items: state.items.map(item => {
        if (item.id === action.restaurantId) {
          return Object.assign({}, item, {
            tags: [
              ...item.tags,
              action.tag.id
            ]
          });
        }
        return item;
      })
    });
  },
  [ActionTypes.POST_TAG_TO_RESTAURANT](state) {
    return Object.assign({}, state, {
      isFetching: true
    });
  },
  [ActionTypes.POSTED_TAG_TO_RESTAURANT](state, action) {
    return Object.assign({}, state, {
      isFetching: false,
      items: state.items.map(item => {
        if (item.id === action.restaurantId) {
          return Object.assign({}, item, {
            tags: [
              ...item.tags,
              action.id
            ]
          });
        }
        return item;
      })
    });
  },
  [ActionTypes.DELETE_TAG_FROM_RESTAURANT](state) {
    return Object.assign({}, state, {
      isFetching: true
    });
  },
  [ActionTypes.DELETED_TAG_FROM_RESTAURANT](state, action) {
    return Object.assign({}, state, {
      isFetching: false,
      items: state.items.map(item => {
        if (item.id === action.restaurantId) {
          return Object.assign({}, item, {
            tags: item.tags.filter(
              tag => tag !== action.id
            )
          });
        }
        return item;
      })
    });
  },
};

const resetRestaurant = (state, action) =>
  Object.assign({}, state, {
    [action.id]: undefined
  });

const resetAllRestaurants = () => ({});

const resetAddTagAutosuggestValue = (state, action) =>
  Object.assign({}, state, {
    [action.id]: Object.assign({}, state[action.id], { addTagAutosuggestValue: '' })
  });

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

export const listUi = {
  [ActionTypes.RECEIVE_RESTAURANTS]: resetAllRestaurants,
  [ActionTypes.RESTAURANT_POSTED]: resetRestaurant,
  [ActionTypes.RESTAURANT_DELETED]: resetRestaurant,
  [ActionTypes.POSTED_TAG_TO_RESTAURANT]: resetAddTagAutosuggestValue,
  [ActionTypes.POSTED_NEW_TAG_TO_RESTAURANT]: resetAddTagAutosuggestValue,
  [ActionTypes.SET_ADD_TAG_AUTOSUGGEST_VALUE](state, action) {
    return Object.assign({}, state, {
      [action.id]: Object.assign({}, state[action.id], { addTagAutosuggestValue: action.value })
    });
  },
  [ActionTypes.SHOW_ADD_TAG_FORM](state, action) {
    return Object.assign({}, state, {
      [action.id]: Object.assign({}, state[action.id], { isAddingTags: true })
    });
  },
  [ActionTypes.HIDE_ADD_TAG_FORM](state, action) {
    return Object.assign({}, state, {
      [action.id]: Object.assign({}, state[action.id], { isAddingTags: false })
    });
  }
};

export const mapUi = {
  [ActionTypes.RECEIVE_RESTAURANTS]: resetAllRestaurants,
  [ActionTypes.RESTAURANT_POSTED]: resetRestaurant,
  [ActionTypes.RESTAURANT_DELETED]: resetRestaurant,
  [ActionTypes.SHOW_INFO_WINDOW](state, action) {
    return Object.assign({}, state, {
      [action.id]: Object.assign({}, state[action.id], { showInfoWindow: true })
    });
  },
  [ActionTypes.HIDE_INFO_WINDOW](state, action) {
    return Object.assign({}, state, {
      [action.id]: Object.assign({}, state[action.id], { showInfoWindow: false })
    });
  }
};

export const tags = {
  [ActionTypes.POSTED_NEW_TAG_TO_RESTAURANT](state, action) {
    return Object.assign({}, state, {
      items: [
        ...state.items,
        action.tag
      ]
    });
  }
};
export const latLng = {};
export const user = {};
