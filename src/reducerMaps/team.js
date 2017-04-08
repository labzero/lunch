import ActionTypes from '../constants/ActionTypes';

export default new Map([
  [ActionTypes.TEAM_PATCHED, (state, action) => action.team]
]);
