import ActionTypes from '../constants/ActionTypes';
import { sortRestaurants } from './restaurants';
import { notify } from './notifications';

let sortTimeout;

const sort = dispatch => {
  clearTimeout(sortTimeout);
  sortTimeout = setTimeout(dispatch.bind(undefined, sortRestaurants()), 1000);
};

const dispatchThenSort = data => dispatch => {
  dispatch(data);
  sort(dispatch);
};

const actionMap = {
  [ActionTypes.RESTAURANT_POSTED]: dispatchThenSort,
  [ActionTypes.VOTE_POSTED]: data => dispatch => {
    dispatch(notify(data));
    dispatch(data);
    sort(dispatch);
  },
  [ActionTypes.VOTE_DELETED]: data => dispatch => {
    dispatch(notify(data));
    dispatch(data);
    sort(dispatch);
  },
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
