import update from 'immutability-helper';
import ActionTypes from '../constants/ActionTypes';
import resetRestaurant from './helpers/resetRestaurant';

export default new Map([
  [ActionTypes.RECEIVE_RESTAURANTS, () => ({
    infoWindow: {},
    showPOIs: false,
    showUnvoted: true
  })
  ],
  [ActionTypes.RESTAURANT_POSTED, (state, action) => resetRestaurant(update(state, {
    newlyAdded: {
      $set: {
        id: action.restaurant.id,
        userId: action.userId
      }
    }
  }), action)
  ],
  [ActionTypes.RESTAURANT_DELETED, resetRestaurant],
  [ActionTypes.SHOW_GOOGLE_INFO_WINDOW, (state, action) => update(state, {
    center: {
      $set: {
        lat: action.latLng.lat,
        lng: action.latLng.lng
      }
    },
    infoWindow: {
      $set: {
        latLng: action.latLng,
        placeId: action.placeId
      }
    }
  })
  ],
  [ActionTypes.SHOW_RESTAURANT_INFO_WINDOW, (state, action) => update(state, {
    center: {
      $set: {
        lat: action.restaurant.lat,
        lng: action.restaurant.lng
      }
    },
    infoWindow: {
      $set: {
        id: action.restaurant.id
      }
    }
  })
  ],
  [ActionTypes.HIDE_INFO_WINDOW, state => update(state, {
    infoWindow: {
      $set: {}
    }
  })
  ],
  [ActionTypes.SET_SHOW_POIS, (state, action) => {
    const updates = {
      showPOIs: {
        $set: action.val
      }
    };

    if (!action.val) {
      updates.infoWindow = {
        latLng: {
          $set: undefined
        },
        placeId: {
          $set: undefined
        }
      };
    }

    return update(state, updates);
  }],
  [ActionTypes.SET_SHOW_UNVOTED, (state, action) => update(state, {
    $merge: {
      showUnvoted: action.val
    }
  })
  ],
  [ActionTypes.SET_CENTER, (state, action) => update(state, {
    center: {
      $set: action.center
    }
  })
  ],
  [ActionTypes.CLEAR_CENTER, state => update(state, {
    center: {
      $set: undefined
    }
  })
  ],
  [ActionTypes.CREATE_TEMP_MARKER, (state, action) => update(state, {
    center: {
      $set: action.result.latLng
    },
    tempMarker: {
      $set: action.result
    }
  })
  ],
  [ActionTypes.CLEAR_TEMP_MARKER, state => update(state, {
    center: {
      $set: undefined
    },
    tempMarker: {
      $set: undefined
    }
  })
  ],
  [ActionTypes.CLEAR_MAP_UI_NEWLY_ADDED, state => update(state, {
    newlyAdded: {
      $set: undefined
    }
  })
  ],
  [ActionTypes.RECEIVE_RESTAURANTS, (state, action) => {
    if (!action.items.length) {
      return update(state, {
        showPOIs: {
          $set: true
        }
      });
    }
    return state;
  }],
]);
