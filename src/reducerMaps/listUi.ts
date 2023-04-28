import update from 'immutability-helper';
import setOrMerge from './helpers/setOrMerge';
import resetRestaurant from './helpers/resetRestaurant';
import { Reducer } from '../interfaces';

const listUi: Reducer<"listUi"> = (state, action) => {
  switch(action.type) {
    case "RESTAURANT_RENAMED":
    case "RESTAURANT_DELETED": {
      return resetRestaurant(state, action);
    }
    case "RESTAURANT_POSTED": {
      return resetRestaurant(update(state, {
        newlyAdded: {
          $set: {
            id: action.restaurant.id,
            userId: action.userId
          }
        }
      }), action)
    }
    case "SET_EDIT_NAME_FORM_VALUE": {
      return update(state, {
        $apply: (target: typeof state) => setOrMerge(target, action.id, { editNameFormValue: action.value })
      })
    }
    case "SHOW_EDIT_NAME_FORM": {
      return update(state, {
        $apply: (target: typeof state) => setOrMerge(target, action.id, { isEditingName: true })
      })
    }
    case "HIDE_EDIT_NAME_FORM": {
      return update(state, {
        $apply: (target: typeof state) => setOrMerge(target, action.id, { isEditingName: false })
      })
    }
    case "SET_FLIP_MOVE": {
      return update(state, {
        flipMove: {
          $set: action.val,
        }
      })
    }
  }
  return state;
}

export default listUi;
