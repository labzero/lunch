import update from 'immutability-helper';
import ActionTypes from '../constants/ActionTypes';
import setOrMerge from './helpers/setOrMerge';
import resetRestaurant from './helpers/resetRestaurant';

export default new Map([
  [ActionTypes.RESTAURANT_RENAMED, resetRestaurant],
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
  [ActionTypes.SET_EDIT_NAME_FORM_VALUE, (state, action) =>
    update(state, {
      $apply: target => setOrMerge(target, action.id, { editNameFormValue: action.value })
    })
  ],
  [ActionTypes.SHOW_EDIT_NAME_FORM, (state, action) =>
    update(state, {
      $apply: target => setOrMerge(target, action.id, { isEditingName: true })
    })
  ],
  [ActionTypes.HIDE_EDIT_NAME_FORM, (state, action) =>
    update(state, {
      $apply: target => setOrMerge(target, action.id, { isEditingName: false })
    })
  ],
  [ActionTypes.SET_FLIP_MOVE, (state, action) =>
    update(state, {
      flipMove: {
        $set: action.val,
      }
    })
  ]
]);
