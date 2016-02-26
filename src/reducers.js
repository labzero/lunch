import {
  INVALIDATE_RESTAURANTS,
  REQUEST_RESTAURANTS, RECEIVE_RESTAURANTS
} from './actions/restaurants';

const initialState = {
  isFetching: false,
  didInvalidate: false,
  items: []
};

function restaurants(state = initialState, action) {
  switch (action.type) {
    case INVALIDATE_RESTAURANTS:
      return Object.assign({}, state, {
        didInvalidate: true
      });
    case REQUEST_RESTAURANTS:
      return Object.assign({}, state, {
        isFetching: true,
        didInvalidate: false
      });
    case RECEIVE_RESTAURANTS:
      return Object.assign({}, state, {
        isFetching: false,
        didInvalidate: false,
        items: action.items
      });
    default:
      return state;
  }
}

export default { restaurants };
