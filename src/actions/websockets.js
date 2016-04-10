import ActionTypes from '../constants/ActionTypes';
import { sortRestaurants } from './restaurants';
import { notify } from './notifications';

let sortTimeout;

const sort = dispatch => {
  clearTimeout(sortTimeout);
  sortTimeout = setTimeout(dispatch.bind(undefined, sortRestaurants()), 1000);
};

const dispatchNotify = data => dispatch => {
  dispatch(notify(data));
  dispatch(data);
};

const notifyDispatch = data => dispatch => {
  dispatch(notify(data));
  dispatch(data);
};

const dispatchSortNotify = data => dispatch => {
  dispatch(data);
  sort(dispatch);
  dispatch(notify(data));
};

const notifyDispatchSort = data => dispatch => {
  dispatch(notify(data));
  dispatch(data);
  sort(dispatch);
};

const actionMap = {
  [ActionTypes.RESTAURANT_POSTED]: dispatchSortNotify,
  [ActionTypes.RESTAURANT_DELETED]: notifyDispatch,
  [ActionTypes.RESTAURANT_RENAMED]: notifyDispatchSort,
  [ActionTypes.VOTE_POSTED]: notifyDispatchSort,
  [ActionTypes.VOTE_DELETED]: notifyDispatchSort,
  [ActionTypes.POSTED_TAG_TO_RESTAURANT]: dispatchNotify,
  [ActionTypes.POSTED_NEW_TAG_TO_RESTAURANT]: dispatchNotify,
  [ActionTypes.DELETED_TAG_FROM_RESTAURANT]: dispatchNotify,
  [ActionTypes.TAG_DELETED]: notifyDispatch,
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
