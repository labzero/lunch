import update from 'immutability-helper';
import ActionTypes from '../constants/ActionTypes';

export default new Map([
  [ActionTypes.TEAM_POSTED, (state, action) => {
    let newState;
    if (action.team.roles) {
      action.team.roles.forEach(role => {
        if (role.userId === state.id) {
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
          $splice: [[state.roles.map(role => role.teamId).indexOf(action.team.id), 1]]
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
          if (role.teamId === action.team.id) {
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
  [ActionTypes.CURRENT_USER_PATCHED, (state, action) => action.user]
]);
