import ActionTypes from '../constants/ActionTypes';
import { sortRestaurants } from './restaurants';

let sortTimeout;

const dispatchThenSort = data => dispatch => {
  dispatch(data);
  clearTimeout(sortTimeout);
  sortTimeout = setTimeout(dispatch.bind(undefined, sortRestaurants()), 1000);
};

const actionMap = {
  [ActionTypes.RESTAURANT_POSTED]: dispatchThenSort,
  [ActionTypes.VOTE_POSTED]: dispatchThenSort,
  [ActionTypes.VOTE_DELETED]: dispatchThenSort
};

export function messageReceived(payload) {
  return dispatch => {
    try {
      const data = JSON.parse(payload);
      const action = actionMap[data.type];
      if (action === undefined) {
        dispatch(data);
      } else {
        dispatch(action(data));
      }
    } catch (SyntaxError) {
      // console.error('Couldn\'t parse message data.');
    }
  };
}
