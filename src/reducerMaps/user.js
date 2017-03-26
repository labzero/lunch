import update from 'immutability-helper';
import ActionTypes from '../constants/ActionTypes';

export default new Map([
  [ActionTypes.USER_ROLE_ADDED, (state, action) => {
    if (action.role.user_id !== state.id) {
      return state;
    }

    return update(state, {
      roles: {
        $push: [action.role]
      }
    });
  }]
]);
