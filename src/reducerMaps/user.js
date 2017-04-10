import update from 'immutability-helper';
import ActionTypes from '../constants/ActionTypes';

export default new Map([
  [ActionTypes.TEAM_POSTED, (state, action) => {
    let newState;
    if (action.team.roles) {
      action.team.roles.forEach(role => {
        if (role.user_id === state.id) {
          newState = update(newState || state, {
            roles: {
              $push: [role]
            }
          });
        }
      });
    }

    return newState || state;
  }],
  [ActionTypes.USER_DELETED, (state, action) => {
    if (action.isSelf) {
      return update(state, {
        roles: {
          $splice: [[state.roles.map(role => role.team_id).indexOf(action.team.id), 1]]
        }
      });
    }
    return state;
  }],
  [ActionTypes.USER_PATCHED, (state, action) => {
    if (action.isSelf) {
      return {
        ...state,
        ...action.user,
        roles: state.roles.map((role) => {
          if (role.team_id === action.team.id) {
            return {
              ...role,
              type: action.user.type
            };
          }
          return role;
        }),
        type: undefined
      };
    }
    return state;
  }],
]);
