import update from 'react-addons-update';
import ActionTypes from '../constants/ActionTypes';
import setOrMerge from './helpers/setOrMerge';
import resetRestaurant from './helpers/resetRestaurant';

const resetAddTagAutosuggestValue = (state, action) =>
  update(state, {
    $apply: target => setOrMerge(target, action.restaurantId, { addTagAutosuggestValue: '' })
  });

export default new Map([
  [ActionTypes.RECEIVE_RESTAURANTS, () => {}],
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
  [ActionTypes.POSTED_TAG_TO_RESTAURANT, resetAddTagAutosuggestValue],
  [ActionTypes.POSTED_NEW_TAG_TO_RESTAURANT, resetAddTagAutosuggestValue],
  [ActionTypes.SET_ADD_TAG_AUTOSUGGEST_VALUE, (state, action) =>
    update(state, {
      $apply: target => setOrMerge(target, action.id, { addTagAutosuggestValue: action.value })
    })
  ],
  [ActionTypes.SHOW_ADD_TAG_FORM, (state, action) =>
    update(state, {
      $apply: target => setOrMerge(target, action.id, { isAddingTags: true })
    })
  ],
  [ActionTypes.HIDE_ADD_TAG_FORM, (state, action) =>
    update(state, {
      $apply: target => setOrMerge(target, action.id, { isAddingTags: false })
    })
  ],
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
  ]
]);
