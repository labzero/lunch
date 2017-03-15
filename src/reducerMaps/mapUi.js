import update from 'react-addons-update';
import ActionTypes from '../constants/ActionTypes';
import resetRestaurant from './helpers/resetRestaurant';

export default new Map([
  [ActionTypes.RECEIVE_RESTAURANTS, () =>
    ({
      showUnvoted: true
    })
  ],
  [ActionTypes.RESTAURANT_POSTED, (state, action) =>
    resetRestaurant(update(state, {
      newlyAdded: {
        $set: {
          id: action.restaurant.id,
          userId: action.userId
        }
      }
    }), action)
  ],
  [ActionTypes.RESTAURANT_DELETED, resetRestaurant],
  [ActionTypes.SHOW_INFO_WINDOW, (state, action) =>
    update(state, {
      center: {
        $set: {
          lat: action.restaurant.lat,
          lng: action.restaurant.lng
        }
      },
      infoWindowId: {
        $set: action.restaurant.id
      }
    })
  ],
  [ActionTypes.HIDE_INFO_WINDOW, state =>
    update(state, {
      infoWindowId: {
        $set: undefined
      }
    })
  ],
  [ActionTypes.SET_SHOW_UNVOTED, (state, action) =>
    update(state, {
      $merge: {
        showUnvoted: action.val
      }
    })
  ],
  [ActionTypes.CLEAR_CENTER, state =>
    update(state, {
      center: {
        $set: undefined
      }
    })
  ],
  [ActionTypes.CREATE_TEMP_MARKER, (state, action) =>
    update(state, {
      center: {
        $set: action.result.latLng
      },
      tempMarker: {
        $set: action.result
      }
    })
  ],
  [ActionTypes.CLEAR_TEMP_MARKER, state =>
    update(state, {
      center: {
        $set: undefined
      },
      tempMarker: {
        $set: undefined
      }
    })
  ],
  [ActionTypes.CLEAR_MAP_UI_NEWLY_ADDED, state =>
    update(state, {
      newlyAdded: {
        $set: undefined
      }
    })
  ]
]);
